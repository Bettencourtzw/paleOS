#!/usr/bin/env bash
# paleOS — user part (run as your normal user). Puts configs, scripts and wallpapers in place.
# Re-running is safe: old configs are moved to a backup, your monitor + wallpaper choices are kept.
# Env: PALEOS_KEYMAP=<console keymap, e.g. pt-latin1>   (otherwise taken from localectl)
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $EUID -ne 0 ]] || { echo "install/user.sh must run as your normal user."; exit 1; }
C=~/.config; backup=$C/paleos-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$C"

# 1. configs: move the old ones aside, copy fresh ones
for d in config/*; do
  n=$(basename "$d")
  [[ -e $C/$n ]] && { mkdir -p "$backup"; mv "$C/$n" "$backup/"; }
  cp -a "$d" "$C/$n"
done
# keep choices the user made last time
for keep in hypr/monitors.lua hypr/wallpaper gtk-3.0/bookmarks; do
  [[ -e $backup/$keep || -L $backup/$keep ]] && cp -a "$backup/$keep" "$C/$keep"
done
[[ -d $backup ]] && echo "Old configs moved to $backup"

# 2. scripts, icons, wallpapers
mkdir -p ~/.local/bin ~/.local/lib ~/.local/share ~/Wallpapers
install -m755 bin/* ~/.local/bin/
rm -f ~/.local/bin/pale-apps                                  # lives in /usr/local/bin
cp -a share/. ~/.local/share/ && cp -n wallpapers/* ~/Wallpapers/
[[ -e $C/hypr/wallpaper || -L $C/hypr/wallpaper ]] || ln -sfn ~/Wallpapers/arch-dark.png "$C/hypr/wallpaper"
sed -i "s|\$HOME|$HOME|" "$C/hypr/hyprpaper.conf"

# 3. keyboard layout for the desktop
km=${PALEOS_KEYMAP:-$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout/{print $2}')}
km=${km%%-*}
case $km in uk) km=gb ;; sv) km=se ;; sg) km=ch ;; cf) km=ca ;; la) km=latam ;; jp106) km=jp ;; dvorak) km=us ;; esac
km=${km:-us}
sed -i "s|kb_layout = \"us\",|kb_layout = \"$km\",|" "$C/hypr/hyprland.lua"

# 4. tray applets that duplicate paleOS's own panels (network, Bluetooth): keep them from autostarting
mkdir -p "$C/autostart"
for a in nm-applet blueman; do printf '[Desktop Entry]\nType=Application\nName=%s\nHidden=true\n' "$a" > "$C/autostart/$a.desktop"; done

# apps that run in a terminal (Neovim, btop…) opened from "Open with": the terminal they open in.
# foot unless you chose another one (one .desktop name per line, first match wins)
[[ -e $C/xdg-terminals.list ]] || echo foot.desktop > "$C/xdg-terminals.list"

# 5. user services (symlinks, so this also works inside the ISO installer's chroot)
U=$C/systemd/user; W=$U/graphical-session.target.wants
mkdir -p "$W" "$U/waybar.service.d" "$U/hypridle.service.d"
cp systemd/paleos-shell.service systemd/paleos-hypr-reload.path systemd/paleos-hypr-reload.service "$U/"
for s in waybar hypridle; do printf '[Service]\nRestart=always\nRestartSec=1\n' > "$U/$s.service.d/restart.conf"; done
ln -sf ../paleos-shell.service "$W/paleos-shell.service"
ln -sf ../paleos-hypr-reload.path "$W/paleos-hypr-reload.path"
ln -sf /usr/lib/systemd/user/waybar.service "$W/waybar.service"
ln -sf /usr/lib/systemd/user/hypridle.service "$W/hypridle.service"     # idle lock + lock before sleep
rm -f "$W/hyprpolkitagent.service"
echo "paleOS user part done."
