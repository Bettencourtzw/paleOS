# paleOS

A monochrome, gaming-ready **Arch Linux + Hyprland** setup. Clean black-and-white desktop,
Omarchy-style menus and panels, and sane defaults for AMD gaming. One script installs it all.

## What you get
- **Top bar** (Waybar) — workspaces, clock, tray, and one icon each for sound, network, bluetooth, display
- **Panels** (Quickshell) — click a bar icon: volume + output picker + mic, Wi-Fi + speed test,
  Bluetooth devices, display scale + night light. Click outside or press Esc to close.
- **Menu** — `SUPER + SPACE`: Apps · Learn · Trigger · Style · Display · Setup · Install · Remove · Update · About · System.
  Type to search apps, `=2+2` calculator, `:smile` emoji, anything else searches the web.
- **Password dialog** — compact Omarchy-style polkit prompt
- **Lock screen, screensaver, login screen, boot splash** — all matching, with an animated Arch logo
- **Gaming** — GameMode, gamescope, FreeSync in fullscreen, tearing allowed for low latency,
  direct scanout, bigger shader cache, LACT for AMD GPU tuning
- **Sandboxed chat** (optional) — Vesktop (Discord) and Telegram via Flatpak with no file access;
  mic, audio and screen sharing still work
- **Neovim** — LazyVim with the Matte Black theme

## Install
On a fresh Arch install with the Hyprland profile (e.g. via `archinstall`):

```bash
git clone https://github.com/<you>/paleOS
cd paleOS
./install.sh
```

Existing configs are backed up to `~/.config/paleos-backup-<date>` first. Reboot when it finishes.

## Keys
| Keys | Action |
|---|---|
| `SUPER + SPACE` | Menu / app search |
| `SUPER + RETURN` | Terminal |
| `SUPER + W` | Close window |
| `SUPER + 1…0` | Workspaces |
| `SUPER + SHIFT + S` | Screenshot to clipboard |
| `SUPER + ESC` | System menu (lock, restart, …) |
| `SUPER + CTRL + L` | Lock |
| `SUPER + K` | All keybindings |

## Customize
| What | File |
|---|---|
| Bar colors / layout | `~/.config/waybar/colors.css`, `config.jsonc`, `style.css` |
| Menu colors | `~/.config/rofi/colors.rasi` |
| Menu entries | `~/.local/bin/menu` |
| Panel colors | `~/.config/quickshell/Theme.qml` |
| Keybindings | `~/.config/hypr/bindings.lua` |
| Monitor | `~/.config/hypr/monitors.lua` |

## Credits
Inspired by [Omarchy](https://github.com/basecamp/omarchy). Keybindings follow Omarchy's layout.
