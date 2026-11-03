# Install

## From the paleOS ISO (recommended)

1. Download `paleos-<date>-x86_64.iso` and its `.sha256` file from the
   [latest release](https://github.com/Bettencourtzw/paleOS/releases/latest), and check it:
   `sha256sum -c paleos-*.iso.sha256`
2. Write the ISO to a USB stick (`sudo dd if=paleos-….iso of=/dev/sdX bs=4M status=progress`, or Ventoy, or balenaEtcher).
3. Boot it in **UEFI** mode. The installer starts on its own. It installs the newest paleOS from
   GitHub, or the copy on the ISO if there's no internet, so an older ISO is fine.
4. Answer the questions:

| Step | Choices |
|---|---|
| Kernel | `linux` (standard), `linux-zen` (desktop responsiveness), `linux-lts` (long-term support) |
| Language & keyboard | Any locale and console keymap; the desktop uses the same layout |
| Timezone | Detected automatically — press Enter to keep it |
| Account | Computer name, username, password |
| Disk | **Erase a disk**, or **install alongside** what's there using free space (keeps Windows) |
| Filesystem | `btrfs` (with optional automatic snapshots via snapper) or `ext4` |
| Encryption | Optional full-disk encryption (LUKS2) |
| Extras | Bluetooth, printing, AUR helper (`yay`), Flatpak |

The GPU driver (AMD, Intel or NVIDIA) and CPU microcode are picked for you. Nothing touches a
disk until you confirm the summary — erasing a disk needs you to type `ERASE`.

The installer uses plain Arch tools (`pacstrap`, `arch-chroot`, GRUB), so the result is a normal
Arch install you can manage like any other. The install log is kept at `/var/log/paleos-install.log`.

## On an existing Arch install

Start from Arch with Hyprland (for example `archinstall` → Desktop → Hyprland), then:

```bash
curl -fsSL https://raw.githubusercontent.com/Bettencourtzw/paleOS/main/boot.sh | bash
```

or

```bash
git clone https://github.com/Bettencourtzw/paleOS && cd paleOS && ./install.sh
```

What it does — and doesn't do:

- **Doesn't force an update.** It asks; the default is no. It only insists if your Hyprland is too old for the config (0.57+).
- **Backs up** any config it replaces to `~/.config/paleos-backup-<date>` (moved, not merged).
- **Keeps your choices** on re-runs: monitor settings and wallpaper stay as you left them.
- Asks before installing the login screen + boot splash, and before AMD GPU tuning (LACT).

Reboot when it's done.

## Uninstall

Your previous configs are in `~/.config/paleos-backup-<date>`. Move them back, and remove
`/etc/sddm.conf.d/paleos.conf` to return to the default login screen.
