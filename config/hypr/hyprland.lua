-- paleOS — Hyprland config. Docs: https://wiki.hypr.land/
-- Your own files, loaded below:  monitors.lua (displays) · bindings.lua (keys)

local home = os.getenv("HOME")

---- DISPLAYS ----
-- monitors.lua holds your monitor settings (Display panel, or edit it: saving applies it right away).
-- The first time a monitor is connected it gets its highest resolution that does 60 Hz (a monitor that
-- can't do 60 gets the rate closest to it), saved to monitors.lua. From then on the saved line is used.
local monitors_file = home .. "/.config/hypr/monitors.lua"
local named, set_monitor = {}, hl.monitor
hl.monitor = function(spec)
    if type(spec) == "table" and spec.output and spec.output ~= "" then named[spec.output] = true end
    return set_monitor(spec)
end
-- a typo in a file you edit shows a message instead of breaking the whole config
local function load(file)
    local f = io.open(file); if not f then return true end; f:close()
    local ok, err = pcall(dofile, file)
    if not ok then hl.notification.create({ text = "Error in " .. file:gsub("^.*/", "") .. ": " .. tostring(err), timeout = 15000 }) end
    return ok
end
local monitors_ok = load(monitors_file)
hl.monitor = set_monitor
local function is_named(m)              -- named by its output (DP-1) or by description (desc:..., matched by prefix)
    if named[m.name] then return true end
    for sel in pairs(named) do
        if sel:sub(1, 5) == "desc:" then local x = hl.get_monitor(sel); if x and x.name == m.name then return true end end
    end
    return false
end

local function first_mode(m)
    -- the highest resolution that does 60 Hz (TVs also list e.g. 4096x2160 at 24 Hz); only a monitor that
    -- can't do 60 at all gets its highest resolution at the rate closest to 60
    local modes, sixty = type(m.available_modes) == "table" and m.available_modes or {}, {}
    for _, md in ipairs(modes) do if md.refresh_rate >= 59 then sixty[#sixty + 1] = md end end
    if #sixty > 0 then modes = sixty end
    local best
    for _, md in ipairs(modes) do
        local px, off = md.width * md.height, math.abs(md.refresh_rate - 60)
        if not best or px > best.px or (px == best.px and off < best.off) then best = { px = px, off = off, md = md } end
    end
    return best and best.md
end
local function new_monitors()            -- at start-up, on reload, and whenever a monitor is plugged in
    if not monitors_ok then return end   -- don't add lines while monitors.lua has an error
    for _, m in ipairs(hl.get_monitors({ all = true }) or {}) do
        local virtual = m.name == "FALLBACK" or m.name:match("^HEADLESS")
        local md = not (virtual or is_named(m)) and first_mode(m)
        if md then
            local spec = { output = m.name, mode = string.format("%dx%d@%g", md.width, md.height, math.floor(md.refresh_rate * 100 + 0.5) / 100),
                           position = "auto", scale = 1, vrr = 0 }
            set_monitor(spec)
            named[m.name] = true
            local f = io.open(monitors_file, "a")
            if f then
                f:write(string.format('hl.monitor({ output = "%s", position = "auto", vrr = 0, mode = "%s", scale = 1 })\n', spec.output, spec.mode))
                f:close()
            end
        end
    end
end
new_monitors()
hl.on("monitor.added", new_monitors)

---- AUTOSTART ----
-- waybar, hypridle and the paleOS shell (panels + password dialog) run as systemd user services so
-- they restart if they crash; these small helpers just start with the session.
hl.on("hyprland.start", function()
    hl.exec_cmd("mako")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
end)

---- ENVIRONMENT ----
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("MESA_SHADER_CACHE_MAX_SIZE", "12G")   -- fewer shader stutters in games
-- include Flatpak apps everywhere (menus, portals, file "open with")
hl.env("XDG_DATA_DIRS", home .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share")
-- NVIDIA-only PCs: video decoding (VA-API) and OpenGL on the NVIDIA driver. Skipped on laptops that
-- also have an Intel/AMD GPU, so apps don't all wake up the NVIDIA card.
local function nvidia_only()
    local found = false
    for i = 0, 7 do
        local f = io.open("/sys/class/drm/card" .. i .. "/device/vendor")
        if f then
            local vendor = f:read("l"); f:close()
            if vendor ~= "0x10de" then return false end
            found = true
        end
    end
    local driver = io.open("/proc/driver/nvidia/version")
    if driver then driver:close() end
    return found and driver ~= nil
end
if nvidia_only() then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
end

---- LOOK ----
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 12,
        border_size = 2,
        col = { active_border = "rgba(e6e6e6ee)", inactive_border = "rgba(222222aa)" },
        layout = "dwindle",
        allow_tearing = true,                  -- only used by the "games" rule below
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
        blur = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },
    -- SUPER + drag: the window lands on the side of the target where you let go (left/right/above/below)
    dwindle = { preserve_split = true, precise_mouse_move = true },
    misc = { force_default_wallpaper = 0, disable_hyprland_logo = true },
    render = {
        direct_scanout = 2,                    -- fullscreen games bypass the compositor
        cm_auto_hdr = 0,                       -- never switch HDR on for a fullscreen app (black flash + dim picture);
    },                                         -- HDR is on or off all the time: Display panel → HDR
    layers = { allow_new_top_layers_over_existing_fullscreen = true },
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",   style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

---- INPUT ----
hl.config({
    input = {
        kb_layout = "us",                      -- set to your layout by the installer
        follow_mouse = 1,
        sensitivity = 0,
        accel_profile = "flat",                -- raw 1:1 mouse, best for games
        touchpad = { natural_scroll = false },
    },
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

---- KEYS ----
load(home .. "/.config/hypr/bindings.lua")

---- WINDOW RULES ----
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({                                 -- XWayland drag-and-drop fix
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({                                 -- games: tearing (lowest latency), keep screen awake
    name = "games",
    match = { class = "^(steam_app_.*|cs2|gamescope|Minecraft.*|minecraft.*)$" },
    fullscreen = true,                       -- games always cover the bar
    immediate = true,
    idle_inhibit = "fullscreen",
})


-- Alt-Tab out of a fullscreen game: the other window takes over fullscreen;
-- switching back gives the game its fullscreen again (default would drop it).
hl.config({ misc = {
    on_focus_under_fullscreen = 1,
    -- when that other window closes, fullscreen goes back to the game (it would otherwise stay windowed)
    exit_window_retains_fullscreen = true,
} })

---- CUSTOMIZE ----
-- Gaps, rounding and animations from the Customize app (SUPER+SPACE → Customize).
pcall(dofile, home .. "/.config/hypr/paleos.lua")

