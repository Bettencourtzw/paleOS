# Make it yours

Start with **SUPER + SPACE → Customize** — background, animation (fps, speed, brightness, pause rules),
window border, gaps, corners, blur, animations and the top bar, all applied instantly. Idle timing is in
**System → Power settings**. Your choices are stored in `~/.config/paleos/settings.json`.

For everything else, it's a plain text file in your home folder. Most changes apply as soon as you save.

| Change | File |
|---|---|
| Bar colors | `~/.config/waybar/colors.css` |
| Bar layout / modules | `~/.config/waybar/config.jsonc` |
| Bar spacing / shape | `~/.config/waybar/style.css` |
| Menu colors | `~/.config/rofi/colors.rasi` |
| Menu look | `~/.config/rofi/theme.rasi` |
| Menu entries | `~/.local/bin/menu` — add a `row icon "Label"` line and a matching `case` line |
| Panel colors | `~/.config/quickshell/Theme.qml` |
| Keybindings | `~/.config/hypr/bindings.lua` — saving applies it right away |
| Monitors | Display panel, or `~/.config/hypr/monitors.lua` — saving the file applies it right away. Monitors not listed get their highest resolution at 60 Hz (or the closest rate they support) |
| Window rules, gaps, animations | `~/.config/hypr/hyprland.lua` |
| Dock | Customize → Dock; pinned apps are in `~/.config/paleos/settings.json` (`dockPinned`) |
| Window header | Customize → Window header: on/off, height, opacity, how long it stays, hover area, which buttons. Point at the gap above a window to show it |
| Wallpaper | Customize (desktop and lock screen follow `~/.config/hypr/wallpaper`) |
| Animated backgrounds | Customize. Your own videos go in `~/Wallpapers/live/` (or use **Add your own images or videos…**). Built-ins are files in `~/.config/quickshell/backgrounds/` — write your own (an Item with `property bool running`, see `Night.qml`), then set `"background"` in `~/.config/paleos/settings.json` to its name (`MyThing.qml` → `"my-thing"`) |
| Lock screen | `~/.config/hypr/hyprlock.conf` |
| Idle timings | System → Power settings (writes `~/.config/hypr/hypridle.conf`) |
| Terminal | `~/.config/foot/foot.ini` |

After editing the bar or panels: **Update → Restart top bar / Restart panels**.
