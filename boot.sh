#!/usr/bin/env bash
# One-line install:  curl -fsSL https://raw.githubusercontent.com/Bettencourtzw/paleOS/main/boot.sh | bash
set -euo pipefail
sudo pacman -S --needed --noconfirm git
dir=~/.local/share/paleOS
if [[ -d $dir/.git ]]; then git -C "$dir" pull --ff-only
else [[ -e $dir ]] && mv "$dir" "$dir.old-$(date +%Y%m%d-%H%M%S)"; git clone https://github.com/Bettencourtzw/paleOS.git "$dir"; fi
exec "$dir/install.sh" </dev/tty
