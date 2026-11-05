#!/usr/bin/env bash
# paleOS — NVIDIA graphics (run as root, called by install/system.sh; safe to re-run).
# Only does something when an NVIDIA GPU is present. It:
#   1. installs the driver and ensures it covers every installed kernel
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

# 1. driver — keep an existing variant, but make sure it covers every installed kernel
all_installed=$(pacman -Qq 2>/dev/null || true)
installed=$(grep -E '^nvidia(-open)?(-beta)?(-lts|-dkms)?$|^nvidia-[0-9]+xx-dkms$' <<<"$all_installed" || true)
modules_dir=${PALEOS_MODULES_DIR:-/usr/lib/modules}
kernels=()
unknown_kernels=()
while IFS= read -r kernel; do
  [[ -n $kernel ]] || continue
  case "$kernel" in
    linux|linux-lts|linux-zen|linux-hardened|linux-rt|linux-rt-lts) kernels+=("$kernel") ;;
    *) unknown_kernels+=("$kernel") ;;
  esac
done < <(find "$modules_dir" -mindepth 2 -maxdepth 2 -type f -name pkgbase -exec cat {} \; 2>/dev/null | sort -u)

# Fresh installs can reach this script before /usr/lib/modules is populated. Fall back to the package DB.
if [[ ${#kernels[@]} -eq 0 && ${#unknown_kernels[@]} -eq 0 ]]; then
  for kernel in linux linux-lts linux-zen linux-hardened linux-rt linux-rt-lts; do
    grep -qx "$kernel" <<<"$all_installed" && kernels+=("$kernel")
  done
fi
if [[ ${#unknown_kernels[@]} -gt 0 ]]; then
  echo "Cannot verify NVIDIA module coverage for kernel(s): ${unknown_kernels[*]}." >&2
  echo "Install that kernel's NVIDIA module and headers explicitly, then run this setup again." >&2
  exit 1
fi
if [[ ${#kernels[@]} -eq 0 ]]; then
  echo "No supported installed kernel was found; refusing to report NVIDIA setup as complete." >&2
  exit 1
fi

pkgs=(libva-nvidia-driver)
pacman -T nvidia-utils >/dev/null || pkgs+=(nvidia-utils)       # unless it (or a variant: beta, 580xx) is installed
if [[ -z $installed ]]; then
  if [[ ${#kernels[@]} -eq 1 && ${kernels[0]} == linux ]]; then
    pkgs+=(nvidia-open)                                  # prebuilt for the stock kernel, nothing to compile
  elif [[ ${#kernels[@]} -eq 1 && ${kernels[0]} == linux-lts ]]; then
    pkgs+=(nvidia-open-lts)
  elif [[ ${#kernels[@]} -eq 2 ]] && printf '%s\n' "${kernels[@]}" | grep -qx linux \
       && printf '%s\n' "${kernels[@]}" | grep -qx linux-lts; then
    pkgs+=(nvidia-open nvidia-open-lts)
  else
    pkgs+=(nvidia-open-dkms)                             # other kernels: built for each kernel installed
    for kernel in "${kernels[@]}"; do pkgs+=("$kernel-headers"); done
  fi
  echo "Installing the NVIDIA driver: ${pkgs[*]}"
else
  echo "NVIDIA driver already installed ($(tr '\n' ' ' <<<"$installed")) — keeping it."
  if grep -q -- '-dkms$' <<<"$installed"; then
    for kernel in "${kernels[@]}"; do pkgs+=("$kernel-headers"); done
  else
    missing=()
    for kernel in "${kernels[@]}"; do
      case "$kernel" in
        linux) grep -qxE 'nvidia(-open)?$' <<<"$installed" || missing+=("$kernel") ;;
        linux-lts) grep -qxE 'nvidia(-open)?-lts$' <<<"$installed" || missing+=("$kernel") ;;
        *) missing+=("$kernel") ;;
      esac
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
      # Current open-driver stock/LTS packages can safely cover one another without changing variants.
      if grep -qE '^nvidia-open(-lts)?$' <<<"$installed" \
         && ! grep -qEv '^nvidia-open(-lts)?$' <<<"$installed" \
         && [[ ${#missing[@]} -eq 1 && ${missing[0]} == linux ]]; then
        pkgs+=(nvidia-open)
      elif grep -qE '^nvidia-open(-lts)?$' <<<"$installed" \
           && ! grep -qEv '^nvidia-open(-lts)?$' <<<"$installed" \
           && [[ ${#missing[@]} -eq 1 && ${missing[0]} == linux-lts ]]; then
        pkgs+=(nvidia-open-lts)
      else
        echo "The installed NVIDIA package does not cover kernel(s): ${missing[*]}." >&2
        echo "Replace the prebuilt driver with the matching DKMS variant and install each kernel's headers, then run setup again." >&2
        exit 1
      fi
    fi
  fi
fi

pacman_conf=${PALEOS_PACMAN_CONF:-/etc/pacman.conf}
if grep -q '^\[multilib\]' "$pacman_conf"; then
  utils=$(grep -E '^nvidia-utils(-beta)?$|^nvidia-[0-9]+xx-utils$' <<<"$all_installed" | head -1 || true)
  case "$utils" in
    ""|nvidia-utils) pkgs+=(lib32-nvidia-utils) ;;
    nvidia-utils-beta) lib32=lib32-nvidia-utils-beta ;;
    nvidia-*xx-utils) lib32="lib32-$utils" ;;
    *) echo "Cannot select 32-bit NVIDIA userspace for $utils." >&2; exit 1 ;;
  esac
  if [[ -n ${lib32:-} ]]; then
    if ! grep -qx "$lib32" <<<"$all_installed"; then
      echo "$utils is installed, but its matching $lib32 package is not." >&2
      echo "Install the matching 32-bit driver variant before running setup again." >&2
      exit 1
    fi
    utils_version=$(pacman -Q "$utils" 2>/dev/null | awk '{print $2}')
    lib32_version=$(pacman -Q "$lib32" 2>/dev/null | awk '{print $2}')
    # The repositories may use different package-release suffixes; the NVIDIA upstream version must match.
    if [[ -z $utils_version || ${utils_version%-*} != "${lib32_version%-*}" ]]; then
      echo "$utils and $lib32 must have the same version (found ${utils_version:-unknown} and ${lib32_version:-unknown})." >&2
      exit 1
    fi
  fi
fi
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
