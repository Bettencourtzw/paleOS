# Make it yours

Start with **SUPER + SPACE → Customize** — wallpaper or animated background, bar position, gaps, corners,
animations and idle timing, all applied instantly. Your choices are stored in `~/.config/paleos/settings.json`.

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
| Lock screen | `~/.config/hypr/hyprlock.conf` |
| Idle timings | `~/.config/hypr/hypridle.conf` |
| Terminal | `~/.config/foot/foot.ini` |

After editing the bar or panels: **Update → Restart top bar / Restart panels**.
