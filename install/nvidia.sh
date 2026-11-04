#!/usr/bin/env bash
# paleOS — NVIDIA graphics (run as root, called by install/system.sh; safe to re-run).
# Only does something when an NVIDIA GPU is present. It:
#   1. installs the driver if none is installed (nvidia-open, or the DKMS build for non-stock kernels)
#   2. loads it early (early KMS), so the boot splash and login screen use the NVIDIA card
#   3. turns on the sleep/wake services, so the desktop comes back after suspend
# Env: PALEOS_NVIDIA_DRYRUN=1 (only print what it would do)
set -euo pipefail
[[ $EUID -eq 0 || ${PALEOS_NVIDIA_DRYRUN:-} == 1 ]] || { echo "install/nvidia.sh must run as root."; exit 1; }
gpus=$(lspci -nn 2>/dev/null | grep -E '(VGA|3D|Display).*\[10de:' || true)
[[ -n $gpus ]] || exit 0
run() { if [[ ${PALEOS_NVIDIA_DRYRUN:-} == 1 ]]; then echo "would run: $*"; else "$@"; fi; }
echo "NVIDIA GPU found: $(sed -E 's/.*: //; s/ \[10de:[^]]*\]//; s/ \(rev [^)]*\)//' <<<"$gpus" | head -1)"

# The open driver (Arch's only current one) supports GTX 16xx / RTX 20xx (Turing) and newer.
# Older cards (Maxwell, Pascal, Volta: GTX 900/1000, Titan V) need the legacy 580xx driver from the AUR.
if ! grep -qE '\b(TU|GA|AD|GB|GH)[0-9]{3}[A-Z]*\b' <<<"$gpus"; then
  echo "This NVIDIA card is older than the GTX 16 / RTX 20 series; Arch's current driver doesn't support it."
  echo "Install the legacy driver from the AUR (Menu → Install → AUR package): nvidia-580xx-dkms nvidia-580xx-utils"
  echo "Leaving the graphics driver as it is."
  exit 0
fi

# 1. driver — keep whatever NVIDIA driver is already installed
installed=$(pacman -Qq 2>/dev/null | grep -E '^nvidia(-open)?(-beta)?(-lts|-dkms)?$|^nvidia-[0-9]+xx-dkms$' || true)
pkgs=(libva-nvidia-driver)
pacman -T nvidia-utils >/dev/null || pkgs+=(nvidia-utils)       # unless it (or a variant: beta, 580xx) is installed
if [[ -z $installed ]]; then
  kernels=$(pacman -Qq linux linux-lts linux-zen linux-hardened linux-rt linux-rt-lts 2>/dev/null || true)
  if [[ $kernels == linux ]]; then
    pkgs+=(nvidia-open)                                  # prebuilt for the stock kernel, nothing to compile
  else
    pkgs+=(nvidia-open-dkms)                             # other kernels: built for each kernel installed
    for k in $kernels; do pkgs+=("$k-headers"); done
    [[ -n $kernels ]] || echo "Note: install your kernel's headers package too, so the driver can be built for it."
  fi
  echo "Installing the NVIDIA driver: ${pkgs[*]}"
else
  echo "NVIDIA driver already installed ($(tr '\n' ' ' <<<"$installed")) — keeping it."
fi
grep -q '^\[multilib\]' /etc/pacman.conf && pkgs+=(lib32-nvidia-utils)   # 32-bit games (Steam)
run pacman -S --needed --noconfirm "${pkgs[@]}"

# 2. early KMS: load the driver in the initramfs, and drop the kms hook (it would pull in nouveau)
conf=/etc/mkinitcpio.conf rebuild=
mods="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
if ! grep -qE '^MODULES=\(.*\bnvidia_drm\b' $conf; then
  run sed -i -E "s/^MODULES=\((.*)\)/MODULES=(\1 $mods)/; s/^MODULES=\( /MODULES=(/" $conf; rebuild=1
fi
if grep -qE '^HOOKS=\(.*\bkms\b' $conf; then
  run sed -i -E '/^HOOKS=/ s/ kms\b//' $conf; rebuild=1
fi
if [[ -n $rebuild ]]; then echo "Rebuilding the boot image with the NVIDIA driver (takes a minute)…"; run mkinitcpio -P; fi

# 3. sleep / wake: keep video memory across suspend, or the desktop comes back black or garbled
run systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service nvidia-suspend-then-hibernate.service 2>/dev/null || true

# a reboot is needed when the driver isn't the one running right now
if [[ ! -e /sys/module/nvidia_drm ]] || ! grep -q Y /sys/module/nvidia_drm/parameters/modeset 2>/dev/null; then
  echo "NVIDIA driver set up — restart the PC to start using it."
else
  echo "NVIDIA driver set up."
fi
