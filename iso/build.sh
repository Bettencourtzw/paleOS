#!/usr/bin/env bash
# Build the paleOS ISO:  sudo ./iso/build.sh   ->  out/paleos-<date>-x86_64.iso
# Starts from Arch's official ISO profile (releng) and adds the paleOS installer.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo."; exit 1; }
REPO=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-/tmp/paleos-iso}
rm -rf "$WORK"; mkdir -p "$WORK"
cp -r /usr/share/archiso/configs/releng "$WORK/profile"
P=$WORK/profile

# name the ISO
sed -i -e 's/^iso_name=.*/iso_name="paleos"/' -e 's/^iso_label=.*/iso_label="PALEOS_$(date +%Y%m)"/' \
       -e 's/^iso_publisher=.*/iso_publisher="paleOS"/' -e 's/^iso_application=.*/iso_application="paleOS installer"/' "$P/profiledef.sh"
grep -vE '^\s*(#|$)' "$REPO/iso/packages.txt" >> "$P/packages.x86_64"
sed -i "s/^airootfs_image_tool_options=.*/airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')/" "$P/profiledef.sh"

# installer + a copy of paleOS itself
cp -a "$REPO/iso/airootfs/." "$P/airootfs/"
install -d "$P/airootfs/usr/share/paleos"
tar -C "$REPO" --exclude=.git --exclude=out --exclude='tools/*/target' -cf - . | tar -C "$P/airootfs/usr/share/paleos" -xf -
sed -i 's|^)$|  ["/usr/local/bin/paleos-setup"]="0:0:755"\n)|' "$P/profiledef.sh"

# prebuild the Rust tool so installed systems don't need a compiler
if command -v cargo >/dev/null; then
  CARGO_TARGET_DIR=$WORK/cargo cargo build --release --manifest-path "$REPO/tools/pale-apps/Cargo.toml" -q
  install -m755 "$WORK/cargo/release/pale-apps" "$P/airootfs/usr/share/paleos/bin/pale-apps"
fi

mkarchiso -v -w "$WORK/build" -o "$REPO/out" "$P"
echo "ISO: $(ls -1 "$REPO"/out/*.iso | tail -1)"
