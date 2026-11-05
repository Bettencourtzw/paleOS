#!/usr/bin/env bash
# paleOS on an existing Arch + Hyprland install:  ./install.sh
# (From the paleOS ISO this runs automatically.)
set -euo pipefail
cd "$(dirname "$0")"
[[ -f /etc/arch-release ]] || { echo "paleOS needs Arch Linux."; exit 1; }
[[ $EUID -ne 0 ]] || { echo "Run as your normal user — it asks for sudo when needed."; exit 1; }
echo "paleOS — monochrome Arch + Hyprland"
read -rp "Upgrade the whole system first? (optional) [y/N] " up
sudo env SSH_CONNECTION="${SSH_CONNECTION:-}" PALEOS_USER="$USER" PALEOS_UPDATE=$([[ $up =~ ^[Yy] ]] && echo 1 || echo 0) bash install/system.sh
# Convert the active console map only if no desktop mapping has been configured.
if ! localectl status | grep -q 'X11 Layout:'; then
  km=$(localectl status | awk -F': ' '/VC Keymap/{print $2}')
  sudo localectl set-keymap "${km:-us}"
fi
bash install/user.sh
echo; echo "Done. Reboot, then: SUPER+SPACE menu · SUPER+RETURN terminal · SUPER+K keybindings."
