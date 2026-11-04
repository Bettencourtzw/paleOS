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
if pacman -Qq pulseaudio >/dev/null 2>&1; then       # replaced by PipeWire (pipewire-pulse)
  echo "Replacing PulseAudio with PipeWire."; pacman -Rdd --noconfirm $(pacman -Qq pulseaudio pulseaudio-bluetooth 2>/dev/null)
fi
if [[ ${PALEOS_UPDATE:-} == 1 ]]; then pacman -Syu --needed --noconfirm $pkgs; else pacman -S --needed --noconfirm $pkgs; fi

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
systemctl enable --now systemd-resolved 2>/dev/null || systemctl enable systemd-resolved   # (no --now in a chroot)
findmnt -n /etc/resolv.conf >/dev/null || ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sysctl --system >/dev/null 2>&1 || true
ufw default deny incoming >/dev/null; ufw default allow outgoing >/dev/null; ufw --force enable >/dev/null 2>&1 || true
systemctl enable ufw
# 10 wrong passwords lock the account for 10 minutes (Arch default is 3)
sed -i -E "s/^#? *deny *=.*/deny = 10/" /etc/security/faillock.conf

# 4. services
systemctl enable bluetooth power-profiles-daemon
[[ -n $user ]] && usermod -aG gamemode "$user"

# 5. NVIDIA: driver, early KMS, sleep/wake (only on PCs with an NVIDIA GPU)
bash install/nvidia.sh

# 6. login screen + boot splash
if ask "Install the paleOS login screen and boot splash?" y; then
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
