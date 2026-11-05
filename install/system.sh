#!/usr/bin/env bash
# paleOS — system part (run as root). Installs packages, login screen, boot splash, services.
# Env: PALEOS_YES=1 (no questions) · PALEOS_UPDATE=1 (upgrade system first) · PALEOS_USER=<name>
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $EUID -eq 0 ]] || { echo "install/system.sh must run as root."; exit 1; }
user=${PALEOS_USER:-${SUDO_USER:-}}
ask() { [[ ${PALEOS_YES:-} == 1 ]] && { [[ ${2:-y} == y ]]; return; }
        local a; read -rp "$1 $([[ ${2:-y} == y ]] && echo '[Y/n]' || echo '[y/N]') " a; a=${a:-${2:-y}}; [[ $a =~ ^[Yy] ]]; }

# 1. packages — never upgrades the whole system unless asked
pkgs=$(grep -vE '^\s*(#|$)' packages.txt | tr '\n' ' ')
have=$(pacman -Q hyprland 2>/dev/null | awk '{print $2}' || true)
if [[ -n $have && $(vercmp "$have" 0.57) -lt 0 ]]; then
  echo "Your Hyprland ($have) is older than 0.57, which paleOS's config needs."
  ask "Upgrade the system now?" y && PALEOS_UPDATE=1 || { echo "Stopping — upgrade first with: sudo pacman -Syu"; exit 1; }
fi
# Let pacman resolve conflicts and download replacements before committing changes.
# Its default for removing a conflicting package is no: ask explicitly on existing audio setups.
pac_args=(--needed --noconfirm)
if pacman -Qq pulseaudio >/dev/null 2>&1; then
  echo "Approve PulseAudio replacement in the single pacman transaction below."
  pac_args=(--needed)
fi
if [[ ${PALEOS_UPDATE:-} == 1 ]]; then pacman -Syu "${pac_args[@]}" $pkgs; else pacman -S "${pac_args[@]}" $pkgs; fi

backup=$(mktemp -d /var/lib/paleos-backup-XXXXXXXX)
for f in /etc/sysctl.d/99-paleos.conf /etc/systemd/resolved.conf.d/paleos.conf /etc/NetworkManager/conf.d/paleos.conf /etc/security/faillock.conf /etc/mkinitcpio.conf /etc/sddm.conf.d/paleos.conf /etc/kernel/cmdline /etc/default/grub /boot/loader/entries/*.conf /etc/ufw; do
  [[ -e $f || -L $f ]] || continue
  mkdir -p "$backup$(dirname "$f")"; cp -a "$f" "$backup$f"
done
echo "System configuration backup: $backup"

# 2. the Rust app indexer used by the menu (prebuilt on the ISO, otherwise compiled once)
if [[ -f bin/pale-apps ]]; then      # (-f: the ISO copy loses its executable bit)
  install -m755 bin/pale-apps /usr/local/bin/pale-apps
else
  build="cargo build --release --quiet --manifest-path tools/pale-apps/Cargo.toml"
  if pacman -Qq rustup >/dev/null 2>&1 && [[ -n $user ]]; then     # rustup conflicts with rust: use the user's toolchain
    tmp=$(runuser -u "$user" -- mktemp -d); runuser -u "$user" -- env CARGO_TARGET_DIR="$tmp" $build
  else
    had_rust=$(pacman -Q rust >/dev/null 2>&1 && echo yes || true)
    pacman -S --needed --noconfirm --asdeps rust
    tmp=$(mktemp -d); CARGO_TARGET_DIR=$tmp $build
    [[ -z $had_rust ]] && pacman -Rns --noconfirm rust >/dev/null || true     # leave the system as clean as before
  fi
  install -m755 "$tmp/release/pale-apps" /usr/local/bin/pale-apps; rm -rf "$tmp"
fi

# 3. safety, privacy, performance
install -Dm644 system/sysctl.d/99-paleos.conf /etc/sysctl.d/99-paleos.conf
install -Dm644 system/resolved.conf.d/paleos.conf /etc/systemd/resolved.conf.d/paleos.conf
install -Dm644 system/NetworkManager/paleos.conf /etc/NetworkManager/conf.d/paleos.conf
# inside the ISO installer's chroot /etc/resolv.conf is a temporary mount; the installer links it afterwards
chroot=${PALEOS_CHROOT:-0}
if systemd-detect-virt --chroot --quiet; then chroot=1; fi
systemctl enable systemd-resolved ufw
if [[ $chroot == 1 ]]; then
  # Configure the target service without changing the live installer's kernel firewall.
  sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf
else
  systemctl start systemd-resolved
  sysctl --system >/dev/null 2>&1 || true
  if [[ -n ${SSH_CONNECTION:-} ]]; then
    read -r peer _ _ port <<<"$SSH_CONNECTION"
    ufw allow from "$peer" to any port "$port" proto tcp
    ufw --force enable
  elif systemctl is-active --quiet sshd; then
    echo "SSH is active: leaving firewall activation to the administrator to preserve access."
  else
    ufw --force enable
  fi
fi
findmnt -n /etc/resolv.conf >/dev/null || ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
# 10 wrong passwords lock the account for 10 minutes (Arch default is 3)
sed -i -E "s/^#? *deny *=.*/deny = 10/" /etc/security/faillock.conf

# 4. services
systemctl enable bluetooth power-profiles-daemon
[[ -n $user ]] && usermod -aG gamemode "$user"

# 5. NVIDIA: driver, early KMS, sleep/wake (only on PCs with an NVIDIA GPU)
bash install/nvidia.sh

# 6. login screen + boot splash
choice=/var/lib/paleos/login-screen
mkdir -p /var/lib/paleos
login=n
if [[ ${PALEOS_REAPPLY:-} == 1 ]]; then
  # Older installations have no receipt: only maintain an already selected paleOS theme.
  if [[ -f $choice ]]; then login=$(cat "$choice")
  elif [[ -f /etc/sddm.conf.d/paleos.conf ]] && systemctl is-enabled --quiet sddm; then login=y; fi
elif ask "Install the paleOS login screen and boot splash?" y; then login=y; fi
printf '%s\n' "$login" > "$choice"
if [[ $login == y ]]; then
  install -d /usr/share/sddm/themes/arch-dark /usr/share/plymouth/themes/arch-dark /etc/sddm.conf.d
  install -m644 themes/sddm-arch-dark/* /usr/share/sddm/themes/arch-dark/
  install -m644 themes/plymouth-arch-dark/* /usr/share/plymouth/themes/arch-dark/
  printf '[Theme]\nCurrent=arch-dark\n' > /etc/sddm.conf.d/paleos.conf
  systemctl enable -f sddm                                           # takes over from another login manager
  if ! grep -qE '^HOOKS=.*plymouth' /etc/mkinitcpio.conf; then
    sed -i -E 's/^HOOKS=\(base (udev|systemd) /HOOKS=(base \1 plymouth /' /etc/mkinitcpio.conf
    grep -qE '^HOOKS=.*plymouth' /etc/mkinitcpio.conf || echo "Note: add 'plymouth' to HOOKS in /etc/mkinitcpio.conf for the boot splash."
  fi
  for f in /boot/loader/entries/*.conf; do [[ -f $f ]] || continue       # systemd-boot
    grep -q '^options.*splash' "$f" || sed -i 's/^options .*/& quiet splash/' "$f"
  done
  for f in /etc/kernel/cmdline /etc/default/grub; do [[ -f $f ]] || continue
    if [[ $f == */grub ]]; then grep -q 'splash' $f || sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&quiet splash /' $f
    else for a in quiet splash; do grep -qw "$a" $f || sed -i "s|\$| $a|" $f; done; fi
  done
  plymouth-set-default-theme arch-dark
  mkinitcpio -P
  [[ -f /etc/default/grub && -d /boot/grub ]] && grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || true
fi

# 7. optional: AMD GPU tuning
if lspci | grep -qiE '(VGA|3D|Display).*AMD' && ask "AMD GPU found. Install LACT for GPU tuning (power, clocks, fans)?" n; then
  pacman -S --needed --noconfirm lact && systemctl enable lactd
fi
echo "paleOS system part done."
