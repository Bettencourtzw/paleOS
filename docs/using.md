# Using paleOS

## The menu — `SUPER + SPACE`

A home list: **Apps · Learn · Customize · Install · Remove · Update · System**.
Sound, network, Bluetooth and display live in the top bar; `SUPER + K` lists every key.

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
| Web App | Any website as its own app, with its icon, in the menu |
| Service | Tailscale, Syncthing, printing, Flatpak |
| AUR helper | `yay`, needed for AUR entries |

**Remove** uninstalls packages or web apps you added.

**Update → System** updates Arch packages. **Update → paleOS** gets the newest paleOS desktop from
GitHub and shows what's new first. Your settings, monitors, wallpaper and keyboard layout are kept;
replaced config folders are saved in `~/.config/paleos-backup-<date>`.

### How paleOS updates reach every PC

Every change to paleOS is pushed to the `main` branch on GitHub, from whichever PC (or person)
made it. Nothing is pushed to your computer automatically: when you want the latest version, open
**SUPER + SPACE → Update → paleOS**. It shows what changed since your last update, asks once, and
then applies it, so every PC that runs it ends up on the same paleOS.

Working on paleOS yourself: edit a clone of the repo (for example `~/Documents/claude/paleOS`),
`git pull` before you start and `git push` to `main` when you're done. Don't edit
`~/.local/share/paleOS`: that is the installed copy, and Update → paleOS resets it to GitHub.

Installing Steam enables multilib and offers a full system upgrade, as required when refreshing
Arch package databases. Review pacman's changes before confirming.

## Customize

**SUPER + SPACE → Customize** opens the settings app — a normal window, with tabs:

| Tab | What you can change |
|---|---|
| Background | A wallpaper, one of six animated backgrounds (Arch binary, Arch pulse, Arch particles, Arch constellation, Night sky, Aurora — point at a card to preview it), or your own images and videos (**Add your own images or videos…**; videos become animated backgrounds) |
| Animation | Frame rate (15–60 fps), speed (built-in backgrounds), brightness, and when to pause: while an app is fullscreen, and/or while windows are open |
| Windows | Border around the active window, gaps, rounded corners, terminal background opacity, blur, animations |
| Top bar | Top or bottom, show/hide, colors |
| Dock | On/off, auto-hide, icon size, background opacity, corners, spacing, distance from the bottom, open-app dots |

Paused backgrounds use no CPU or GPU. Everything applies as you click.

## Power settings

**SUPER + SPACE → System → Power settings** (or `SUPER + ESC`): power mode (performance / balanced /
saver), screensaver, lock and sleep timers, and Lock / Sleep / Restart / Shut down.

## The dock

A dock sits at the bottom: an apps button, your pinned apps, then open apps (dots show how
many windows each has; the app you're in gets a wider one). Click to open or switch to an app,
right-click for a menu (open, new window, pin/unpin, close), and drag icons to reorder them — drop an
open app among the pinned ones to pin it. Turn it off or restyle it in Customize → Dock.

## The top bar

Workspaces on the left, the clock in the middle, and on the right: tray (click `‹`), Bluetooth,
network, sound, display. Each icon opens a small panel; click outside it or press Esc to close.

| Panel | What's in it |
|---|---|
| Sound | Volume, mute, output device, microphone |
| Network | Ethernet/Wi-Fi status, Wi-Fi networks (with password entry), speed test |
| Bluetooth | On/off, paired devices, scan for new ones |
| Display | Resolution and refresh rate (dropdowns with your monitor's supported modes), scale (every sharp scale your monitor supports, applied when you let go), HDR, night light, the settings file |

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
| `SUPER + J` | Flip a split: stacked ↔ side by side |
| `SUPER + L` | Switch layout: tiling ↔ master (one big window + a stack) |
| `SUPER + 1 … 0` | Switch workspace |
| `SUPER + SHIFT + 1 … 0` | Move window to workspace |
| `SUPER + arrows` | Move focus |
| `ALT + TAB` | Next window |
| `SUPER + SHIFT + S` | Screenshot to clipboard (also saved to `~/Pictures/Screenshots`) |
| `PRINT` | Screenshot with editor |
| `SUPER + CTRL + L` | Lock |
| `SUPER + ESC` | System menu (lock, suspend, restart, power mode) |
| `SUPER + K` | Every keybinding, searchable |


## Idle

By default the screensaver starts after 5 minutes (an animated Arch logo) and the screen locks after 10.
Change the timings in Power settings, or toggle idle locking with `SUPER + CTRL + I`.
