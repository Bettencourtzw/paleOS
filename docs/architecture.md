# How it's built

paleOS is small on purpose: standard Arch packages, configured with plain files.

| Part | Built with | Lives in |
|---|---|---|
| Compositor | Hyprland (Lua config) | `config/hypr/` |
| Top bar | Waybar | `config/waybar/` |
| Panels, password dialog, Customize app, animated background | Quickshell (QML), one process | `config/quickshell/` |
| Applying Customize settings | `bin/paleos-apply` | `bin/` |
| Web apps | `bin/webapp` | `bin/` |
| Kernel tuning, DNS, firewall | sysctl, systemd-resolved, NetworkManager, ufw | `system/` |
| Menu | rofi + `bin/launcher` and `bin/menu` | `bin/`, `config/rofi/` |
| App index for the menu | `pale-apps` (Rust, no dependencies) | `tools/pale-apps/` |
| Monitor settings helper | `bin/display` (used by menu and panel) | `bin/` |
| Notifications / OSD | mako, swayosd | `config/mako/` |
| Lock / idle / wallpaper | hyprlock, hypridle, hyprpaper | `config/hypr/` |
| Screensaver | Quickshell overlay (`Screensaver.qml`) | `config/quickshell/` |
| Login screen | SDDM theme (QML) | `themes/sddm-arch-dark/` |
| Boot splash | Plymouth script theme | `themes/plymouth-arch-dark/` |
| Installer (existing Arch) | `install.sh` → `install/system.sh` (root) + `install/user.sh` (you) | `install/` |
| ISO installer | archiso + `paleos-setup` (gum) | `iso/` |

## Why Rust for the app index

The menu lists every installed app each time it opens. The first version was Python and took
~43 ms per open, almost all of it interpreter start-up. `pale-apps` does the same work —
XDG + Flatpak app folders, icons, hidden entries — in ~2 ms. The ISO ships it prebuilt; on an
existing install it's compiled once and the compiler is removed again.

Other parts were measured and left alone: the screensaver uses ~1 % of one core because the
terminal only redraws what changed, so a rewrite wouldn't be noticeable.

## Services

`waybar` and `paleos-shell` (Quickshell) run as systemd user services so they restart if they
crash. mako, swayosd, hyprpaper and hypridle are started by Hyprland at login.
