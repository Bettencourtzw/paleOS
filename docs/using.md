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

**SUPER + SPACE → Customize** opens the settings app — a normal window, with tabs:

| Tab | What you can change |
|---|---|
| Background | A wallpaper, one of eight animated backgrounds (Arch pulse, Arch particles, Arch constellation, Night sky, Aurora, Waves, Snow, Fireflies — point at a card to preview it), or your own images and videos (**Add your own images or videos…**; videos become animated backgrounds) |
| Animation | Frame rate (15–60 fps), speed, detail, brightness, and when to pause: while an app is fullscreen, and/or while windows are open |
| Windows | Border around the active window, gaps, rounded corners, blur, animations |
| Top bar | Top or bottom, show/hide, colors |

Paused backgrounds use no CPU or GPU. Everything applies as you click.

## Power settings

**SUPER + SPACE → System → Power settings** (or `SUPER + ESC`): power mode (performance / balanced /
saver), screensaver, lock and sleep timers, and Lock / Sleep / Restart / Shut down.

## The top bar

Workspaces on the left, the clock in the middle, and on the right: tray (click `‹`), Bluetooth,
network, sound, display. Each icon opens a small panel; click outside it or press Esc to close.

| Panel | What's in it |
|---|---|
| Sound | Volume, mute, output device, microphone |
| Network | Ethernet/Wi-Fi status, Wi-Fi networks (with password entry), speed test |
| Bluetooth | On/off, paired devices, scan for new ones |
| Display | Resolution and refresh rate (dropdowns with your monitor's supported modes), scale, night light, the settings file |

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

By default the screensaver starts after 5 minutes (an animated Arch logo) and the screen locks after 10.
Change the timings in Power settings, or toggle idle locking with `SUPER + CTRL + I`.
