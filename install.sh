#!/usr/bin/env bash
# paleOS installer. Run on a fresh Arch Linux install (with Hyprland), as your normal user.
# It only installs the OS layer — bar, panels, menu, keybinds, lock/login/boot screens.
# It never upgrades your system unless you say yes, and backs up configs it replaces.
set -euo pipefail
cd "$(dirname "$0")"
REPO=$PWD
ask() { local d=${2:-y} a; read -rp "$1 $([[ $d == y ]] && echo '[Y/n]' || echo '[y/N]') " a; a=${a:-$d}; [[ $a =~ ^[Yy] ]]; }

[[ -f /etc/arch-release ]] || { echo "paleOS needs Arch Linux."; exit 1; }
[[ $EUID -ne 0 ]] || { echo "Run as your normal user (sudo is used when needed)."; exit 1; }

echo "paleOS — monochrome Arch + Hyprland"
echo

# 1. Packages ----------------------------------------------------------------
pkgs=$(grep -vE '^\s*(#|$)' packages.txt | tr '\n' ' ')
if ask "Update the system before installing? (recommended on Arch, but optional)" n; then
  sudo pacman -Syu --needed --noconfirm $pkgs
else
  sudo pacman -S --needed --noconfirm $pkgs
fi

# 2. Configs -----------------------------------------------------------------
backup=~/.config/paleos-backup-$(date +%Y%m%d-%H%M%S)
for d in config/*; do
  n=$(basename "$d")
  if [[ -e ~/.config/$n ]]; then mkdir -p "$backup"; cp -a ~/.config/"$n" "$backup"/; fi
  mkdir -p ~/.config/"$n" && cp -a "$d"/. ~/.config/"$n"/
done
[[ -d $backup ]] && echo "Your old configs are in $backup"

mkdir -p ~/.local/bin ~/.local/lib ~/.local/share ~/Wallpapers ~/Pictures/Screenshots
cp -a bin/. ~/.local/bin/ && chmod +x ~/.local/bin/*
cp -a lib/. ~/.local/lib/
cp -a share/. ~/.local/share/
cp -a wallpapers/. ~/Wallpapers/
sed -i "s|\$HOME|$HOME|" ~/.config/hypr/hyprpaper.conf

# 3. Services ----------------------------------------------------------------
mkdir -p ~/.config/systemd/user/waybar.service.d
cp systemd/paleos-shell.service ~/.config/systemd/user/
printf '[Service]\nRestart=always\nRestartSec=1\n' > ~/.config/systemd/user/waybar.service.d/restart.conf
systemctl --user daemon-reload
systemctl --user enable paleos-shell.service waybar.service
systemctl --user disable hyprpolkitagent.service 2>/dev/null || true
sudo systemctl enable bluetooth power-profiles-daemon
sudo usermod -aG gamemode "$USER"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark 2>/dev/null || true

# 4. Login screen + boot splash ------------------------------------------------
if ask "Install the paleOS login screen and boot splash?"; then
  sudo install -d /usr/share/sddm/themes/arch-dark /usr/share/plymouth/themes/arch-dark /etc/sddm.conf.d
  sudo install -m644 themes/sddm-arch-dark/* /usr/share/sddm/themes/arch-dark/
  sudo install -m644 themes/plymouth-arch-dark/* /usr/share/plymouth/themes/arch-dark/
  printf '[Theme]\nCurrent=arch-dark\n' | sudo tee /etc/sddm.conf.d/paleos.conf >/dev/null
  sudo systemctl enable sddm
  grep -q plymouth /etc/mkinitcpio.conf || sudo sed -i -E 's/^HOOKS=\(base (udev|systemd) /HOOKS=(base \1 plymouth /' /etc/mkinitcpio.conf
  if [[ -f /etc/kernel/cmdline ]]; then
    for a in quiet splash; do grep -qw "$a" /etc/kernel/cmdline || sudo sed -i "s|\$| $a|" /etc/kernel/cmdline; done
  else
    echo "Note: add 'quiet splash' to your kernel command line to see the boot splash."
  fi
  sudo plymouth-set-default-theme arch-dark
  sudo mkinitcpio -P
fi

# 5. Optional: AMD GPU tuning ---------------------------------------------------
if lspci | grep -qiE '(VGA|Display).*AMD' && ask "AMD GPU found. Install LACT for GPU tuning (power, clocks, fans)?" n; then
  sudo pacman -S --needed --noconfirm lact
  sudo systemctl enable lactd
fi

echo
echo "Done. Reboot, then: SUPER+SPACE menu · SUPER+RETURN terminal · SUPER+K all keybindings."
