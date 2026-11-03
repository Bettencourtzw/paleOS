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
| Keybindings | `~/.config/hypr/bindings.lua` |
| Monitors | `~/.config/hypr/monitors.lua` (also: Display panel or Display menu) |
| Window rules, gaps, animations | `~/.config/hypr/hyprland.lua` |
| Wallpaper | Customize (desktop and lock screen follow `~/.config/hypr/wallpaper`) |
| Animated backgrounds | Customize. Your own videos go in `~/Wallpapers/live/` (or use **Add your own images or videos…**). Built-ins are files in `~/.config/quickshell/backgrounds/` — write your own (an Item with `property bool running`, see `Night.qml`), then set `"background"` in `~/.config/paleos/settings.json` to its name (`MyThing.qml` → `"my-thing"`) |
| Lock screen | `~/.config/hypr/hyprlock.conf` |
| Idle timings | System → Power settings (writes `~/.config/hypr/hypridle.conf`) |
| Terminal | `~/.config/foot/foot.ini` |

After editing the bar or panels: **Update → Restart top bar / Restart panels**.
