#!/usr/bin/env bash
# paleOS on an existing Arch + Hyprland install:  ./install.sh
# (From the paleOS ISO this runs automatically.)
set -euo pipefail
cd "$(dirname "$0")"
[[ -f /etc/arch-release ]] || { echo "paleOS needs Arch Linux."; exit 1; }
[[ $EUID -ne 0 ]] || { echo "Run as your normal user — it asks for sudo when needed."; exit 1; }
echo "paleOS — monochrome Arch + Hyprland"
read -rp "Upgrade the whole system first? (optional) [y/N] " up
sudo env PALEOS_USER="$USER" PALEOS_UPDATE=$([[ $up =~ ^[Yy] ]] && echo 1 || echo 0) bash install/system.sh
bash install/user.sh
echo; echo "Done. Reboot, then: SUPER+SPACE menu · SUPER+RETURN terminal · SUPER+K keybindings."
