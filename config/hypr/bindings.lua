-- Omarchy keybindings, ported to plain Hyprland (no Omarchy scripts needed).
-- Loaded from hyprland.lua. Press SUPER + K to see them all.

local o = {}

function o.bind(keys, description, dispatcher, options)
  local opts = options or {}
  if description then opts.description = description end
  if type(dispatcher) == "string" then dispatcher = hl.dsp.exec_cmd(dispatcher) end
  hl.bind(keys, dispatcher, opts)
end

local terminal = "foot"
local browser  = "chromium"
local files    = "nautilus --new-window"
local tui      = function(cmd) return "foot --app-id=tui." .. cmd .. " -e " .. cmd end

---- APPS ---------------------------------------------------------------------
o.bind("SUPER + RETURN", "Terminal", terminal)
o.bind("SUPER + SHIFT + RETURN", "Browser", browser)
o.bind("SUPER + SHIFT + B", "Browser", browser)
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", browser .. " --incognito")
o.bind("SUPER + SHIFT + F", "File manager", files)
o.bind("SUPER + SHIFT + N", "Editor", "foot -e nvim")
o.bind("SUPER + SPACE", "Menu", "~/.local/bin/launcher")
o.bind("SUPER + K", "Show key bindings", "~/.local/bin/keybinds-menu")
o.bind("SUPER + ESCAPE", "System menu", "~/.local/bin/launcher system")
o.bind("SUPER + ALT + SPACE", "Setup menu", "~/.local/bin/launcher setup")
o.bind("XF86PowerOff", "Power menu", "~/.local/bin/power-menu", { locked = true })
o.bind("XF86Calculator", "Calculator", "gnome-calculator")

o.bind("SUPER + CTRL + A", "Audio controls", "qs ipc call panel toggle sound")
o.bind("SUPER + CTRL + B", "Bluetooth controls", "qs ipc call panel toggle bluetooth")
o.bind("SUPER + CTRL + W", "Wifi controls", "qs ipc call panel toggle network")
o.bind("SUPER + CTRL + T", "Activity", tui("btop"))

---- WINDOWS ------------------------------------------------------------------
o.bind("SUPER + W", "Close window", hl.dsp.window.close())
o.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
o.bind("SUPER + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + ALT + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))

o.bind("SUPER + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))

o.bind("SUPER + SHIFT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + SHIFT + UP", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + DOWN", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

o.bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
o.bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
o.bind("ALT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())
o.bind("ALT + SHIFT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())

-- Resize with the - and = keys (key codes, so they work on the PT layout too)
o.bind("SUPER + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- Your own: move floating windows with the keyboard (50px per press)
o.bind("SUPER + CTRL + ALT + LEFT", "Move floating window left", hl.dsp.window.move({ x = -50, y = 0, relative = true }))
o.bind("SUPER + CTRL + ALT + RIGHT", "Move floating window right", hl.dsp.window.move({ x = 50, y = 0, relative = true }))
o.bind("SUPER + CTRL + ALT + UP", "Move floating window up", hl.dsp.window.move({ x = 0, y = -50, relative = true }))
o.bind("SUPER + CTRL + ALT + DOWN", "Move floating window down", hl.dsp.window.move({ x = 0, y = 50, relative = true }))

---- GROUPS -------------------------------------------------------------------
o.bind("SUPER + G", "Toggle window grouping", hl.dsp.group.toggle())
o.bind("SUPER + ALT + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))
o.bind("SUPER + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
o.bind("SUPER + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
o.bind("SUPER + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
o.bind("SUPER + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))
o.bind("SUPER + ALT + TAB", "Next window in group", hl.dsp.group.next())
o.bind("SUPER + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())
o.bind("SUPER + CTRL + LEFT", "Move grouped window focus left", hl.dsp.group.prev())
o.bind("SUPER + CTRL + RIGHT", "Move grouped window focus right", hl.dsp.group.next())

---- WORKSPACES ---------------------------------------------------------------
-- code:10..19 are the 1..0 number-row keys, independent of keyboard layout
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

o.bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
o.bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))
o.bind("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))

---- CLIPBOARD ----------------------------------------------------------------
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down", window = "activewindow" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up", window = "activewindow" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

o.bind("SUPER + C", "Universal copy", send_shortcut_once("CTRL", "Insert"))
o.bind("SUPER + V", "Universal paste", send_shortcut_once("SHIFT", "Insert"))
o.bind("SUPER + X", "Universal cut", send_shortcut_once("CTRL", "X"))

---- UTILITIES ----------------------------------------------------------------
o.bind("SUPER + SHIFT + SPACE", "Toggle top bar", "pkill -SIGUSR1 waybar")
o.bind("SUPER + COMMA", "Dismiss last notification", "makoctl dismiss")
o.bind("SUPER + SHIFT + COMMA", "Dismiss all notifications", "makoctl dismiss --all")
o.bind("SUPER + CTRL + COMMA", "Toggle silencing notifications", "makoctl mode -t do-not-disturb")
o.bind("SUPER + ALT + COMMA", "Invoke last notification", "makoctl invoke")
o.bind("SUPER + SHIFT + ALT + COMMA", "Restore last notification", "makoctl restore")
o.bind("SUPER + CTRL + I", "Toggle locking on idle", "~/.local/bin/toggle-idle")
o.bind("SUPER + CTRL + N", "Toggle nightlight", "~/.local/bin/toggle-nightlight")
o.bind("SUPER + CTRL + ALT + T", "Show time", "notify-send -u low \"$(date +'%A %H:%M — %d %B')\"")
o.bind("SUPER + CTRL + L", "Lock system", "pidof hyprlock || hyprlock")

o.bind("PRINT", "Screenshot (edit)", "~/.local/bin/screenshot edit")
o.bind("SUPER + SHIFT + S", "Screenshot to clipboard", "~/.local/bin/screenshot")
o.bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")

o.bind("SUPER + CTRL + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
o.bind("SUPER + CTRL + ALT + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

---- MEDIA --------------------------------------------------------------------
o.bind("XF86AudioRaiseVolume", "Volume up", "swayosd-client --output-volume raise", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "swayosd-client --output-volume lower", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", "swayosd-client --output-volume mute-toggle", { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", "swayosd-client --input-volume mute-toggle", { locked = true })
o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", "swayosd-client --output-volume +1", { locked = true, repeating = true })
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise", "swayosd-client --output-volume -1", { locked = true, repeating = true })
o.bind("XF86AudioNext", "Next track", "swayosd-client --playerctl next", { locked = true })
o.bind("XF86AudioPause", "Pause", "swayosd-client --playerctl play-pause", { locked = true })
o.bind("XF86AudioPlay", "Play", "swayosd-client --playerctl play-pause", { locked = true })
o.bind("XF86AudioPrev", "Previous track", "swayosd-client --playerctl previous", { locked = true })
