#!/usr/bin/env bash
# paleOS installer — run on a fresh Arch Linux + Hyprland install, as your normal user.
#   git clone https://github.com/<you>/paleOS && cd paleOS && ./install.sh
set -euo pipefail
cd "$(dirname "$0")"
REPO=$PWD
ask() { read -rp "$1 [Y/n] " a; [[ -z $a || $a =~ ^[Yy] ]]; }

[[ -f /etc/arch-release ]] || { echo "paleOS needs Arch Linux."; exit 1; }
[[ $EUID -ne 0 ]] || { echo "Run as your normal user (it asks for sudo when needed)."; exit 1; }

echo "==> Enabling multilib (Steam)"
grep -q '^\[multilib\]' /etc/pacman.conf || sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf

echo "==> Installing packages"
sudo pacman -Syu --needed --noconfirm $(grep -vE '^\s*(#|$)' packages.txt)

echo "==> Installing configs (existing ones are backed up)"
backup=~/.config/paleos-backup-$(date +%Y%m%d-%H%M%S)
for d in "$REPO"/config/*; do
  n=$(basename "$d")
  [[ -e ~/.config/$n ]] && { mkdir -p "$backup"; cp -a ~/.config/"$n" "$backup"/; }
  mkdir -p ~/.config/"$n" && cp -a "$d"/. ~/.config/"$n"/
done
mkdir -p ~/.local/bin ~/.local/lib ~/.local/share ~/Wallpapers ~/Pictures/Screenshots
cp -a bin/. ~/.local/bin/ && chmod +x ~/.local/bin/*
cp -a lib/. ~/.local/lib/ && cp -a share/. ~/.local/share/ && cp -a wallpapers/. ~/Wallpapers/
sed -i "s|\$HOME|$HOME|" ~/.config/hypr/hyprpaper.conf

echo "==> User services"
mkdir -p ~/.config/systemd/user/waybar.service.d
cp systemd/paleos-shell.service ~/.config/systemd/user/
printf '[Service]\nRestart=always\nRestartSec=1\n' > ~/.config/systemd/user/waybar.service.d/restart.conf
systemctl --user daemon-reload
systemctl --user enable paleos-shell.service waybar.service
systemctl --user disable hyprpolkitagent.service 2>/dev/null || true

echo "==> Dark mode"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark || true

echo "==> Steam: hide the Friends popup on startup"
[[ -f /usr/share/applications/steam.desktop ]] && mkdir -p ~/.local/share/applications && \
  sed -E "s|^Exec=/usr/bin/steam|Exec=$HOME/.local/bin/steam-launch|; s|^Exec=$HOME/.local/bin/steam-launch steam://open/friends|Exec=/usr/bin/steam steam://open/friends|" \
  /usr/share/applications/steam.desktop > ~/.local/share/applications/steam.desktop

if ask "Install the login screen (SDDM) and boot splash (Plymouth)?"; then
  sudo install -d /usr/share/sddm/themes/arch-dark /usr/share/plymouth/themes/arch-dark /etc/sddm.conf.d
  sudo install -m644 themes/sddm-arch-dark/* /usr/share/sddm/themes/arch-dark/
  sudo install -m644 themes/plymouth-arch-dark/* /usr/share/plymouth/themes/arch-dark/
  printf '[Theme]\nCurrent=arch-dark\n' | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
  sudo systemctl enable sddm
  grep -q plymouth /etc/mkinitcpio.conf || sudo sed -i 's/^HOOKS=(base udev /HOOKS=(base udev plymouth /; s/^HOOKS=(base systemd /HOOKS=(base systemd plymouth /' /etc/mkinitcpio.conf
  [[ -f /etc/kernel/cmdline ]] && for a in quiet splash; do grep -qw "$a" /etc/kernel/cmdline || sudo sed -i "s|\$| $a|" /etc/kernel/cmdline; done
  sudo plymouth-set-default-theme arch-dark && sudo mkinitcpio -P
fi

if lspci | grep -qiE 'VGA.*AMD|Display.*AMD' && ask "AMD GPU found. Enable GPU tuning (LACT, overclock unlock)?"; then
  [[ -f /etc/kernel/cmdline ]] && { grep -qw amdgpu.ppfeaturemask=0xffffffff /etc/kernel/cmdline || sudo sed -i 's|$| amdgpu.ppfeaturemask=0xffffffff|' /etc/kernel/cmdline; sudo mkinitcpio -P; }
  sudo systemctl enable --now lactd power-profiles-daemon
fi
sudo usermod -aG gamemode "$USER"

if ask "Install Discord (Vesktop) and Telegram, sandboxed (no file access, mic/audio/screenshare allowed)?"; then
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install --user -y flathub dev.vencord.Vesktop org.telegram.desktop
  for a in dev.vencord.Vesktop org.telegram.desktop; do
    flatpak override --user "$a" --nofilesystem=home --nofilesystem=host --nofilesystem=xdg-download --nofilesystem=xdg-pictures \
      --nofilesystem=xdg-videos --nofilesystem=xdg-documents --nofilesystem=xdg-music --nofilesystem=~/.steam \
      --nodevice=all --device=dri --filesystem=xdg-run/pipewire-0 --socket=pulseaudio --socket=wayland
  done
fi

echo
echo "paleOS installed. Reboot, then press SUPER+SPACE for the menu and SUPER+K for keybindings."
