# Using paleOS

## The menu — `SUPER + SPACE`

A home list: **Apps · Learn · Trigger · Customize · Display · Setup · Install · Remove · Update · About · System**.

- **Right / Enter** opens a section, **Left** goes back, **Esc** closes.
- Start typing to search your apps straight away.
- `=2+2` calculator · `:smile` emoji · anything else searches the web.

## Install and Remove

**Install** has ready-made lists so you don't need to remember package names:

| Entry | What you can add |
|---|---|
| Package / AUR package | Search every Arch (or AUR) package |
| Browser | Firefox, Chromium, Brave, Zen, Google Chrome |
| Editor | VS Code, Zed, Helix, Neovim + LazyVim |
| Terminal | Ghostty, Alacritty, Kitty, WezTerm |
| Development | Rust, Go, Node.js, Python (uv), Java, C/C++, Docker, GitHub CLI |
| Gaming | Steam, Lutris, Heroic, MangoHud, Prism Launcher, Gamescope |
| Web App | Any website as its own app, with its icon, in the menu |
| Service | Tailscale, Syncthing, printing, Flatpak |
| AUR helper | `yay`, needed for AUR entries |

**Remove** uninstalls packages or web apps you added.

## Customize

**SUPER + SPACE → Customize** opens the settings app: wallpaper or the animated night-sky
background, top bar position, window gaps and corners, animations, screensaver and lock timing.
Everything applies as you click.

The animated background only moves while you can see it — it freezes when an app is fullscreen
(games included) and, by default, whenever windows are open on that desktop.

## The top bar

Workspaces on the left, the clock in the middle, and on the right: tray (click `‹`), Bluetooth,
network, sound, display. Each icon opens a small panel; click outside it or press Esc to close.

| Panel | What's in it |
|---|---|
| Sound | Volume, mute, output device, microphone |
| Network | Ethernet/Wi-Fi status, Wi-Fi networks (with password entry), speed test |
| Bluetooth | On/off, paired devices, scan for new ones |
| Display | Scale (snaps to sharp values), night light, the display settings file |

## Keys

| Keys | Action |
|---|---|
| `SUPER + SPACE` | Menu and app search |
| `SUPER + RETURN` | Terminal |
| `SUPER + SHIFT + B` | Browser |
| `SUPER + SHIFT + F` | Files |
| `SUPER + W` | Close window |
| `SUPER + F` | Fullscreen |
| `SUPER + T` | Float / tile |
| `SUPER + 1 … 0` | Switch workspace |
| `SUPER + SHIFT + 1 … 0` | Move window to workspace |
| `SUPER + arrows` | Move focus |
| `ALT + TAB` | Next window |
| `SUPER + SHIFT + S` | Screenshot to clipboard (also saved to `~/Pictures/Screenshots`) |
| `PRINT` | Screenshot with editor |
| `SUPER + CTRL + L` | Lock |
| `SUPER + ESC` | System menu (lock, suspend, restart, power mode) |
| `SUPER + K` | Every keybinding, searchable |

## Gaming

- **FreeSync** in fullscreen, **tearing allowed** for games (lowest latency), fullscreen games bypass the compositor.
- Games (Steam/Proton, CS2, gamescope, Minecraft) always open **fullscreen over the bar**, and the screen won't sleep while they run.
- **Alt-Tab** out of a fullscreen game shows the other window full-size; switching back restores the game's fullscreen.
- **GameMode** is installed: add `gamemoderun %command%` to a Steam game's launch options.
- Power mode (performance / balanced / power-saver) is in **System**.

## Idle

After 5 minutes the screensaver starts (an animated Arch logo); after 10 the screen locks.
Toggle idle locking with `SUPER + CTRL + I`.
