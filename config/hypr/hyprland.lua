-- paleOS — Hyprland config. Docs: https://wiki.hypr.land/
-- Your own files, loaded below:  monitors.lua (displays) · bindings.lua (keys)

local home = os.getenv("HOME")

---- DISPLAYS ----
-- monitors.lua holds your choices (Display panel, or edit it: saving applies it right away).
-- A monitor it doesn't name gets its highest resolution at 60 Hz, or the rate closest to 60 that
-- resolution supports, read from what the monitor reports. Nothing here is fixed to one screen.
local named, set_monitor = {}, hl.monitor
hl.monitor = function(spec)
    if type(spec) == "table" and spec.output and spec.output ~= "" then named[spec.output] = true end
    return set_monitor(spec)
end
dofile(home .. "/.config/hypr/monitors.lua")
hl.monitor = set_monitor

local function default_mode(m)
    local best
    for _, md in ipairs(type(m.available_modes) == "table" and m.available_modes or {}) do
        local px, off = md.width * md.height, math.abs(md.refresh_rate - 60)
        if not best or px > best.px or (px == best.px and off < best.off) then best = { px = px, off = off, md = md } end
    end
    return best and best.md
end
local function auto_monitor(m)
    if named[m.name] or named["desc:" .. (m.description or "")] then return end
    local md = default_mode(m)
    if md then
        set_monitor({ output = m.name, mode = string.format("%dx%d@%.3f", md.width, md.height, md.refresh_rate),
                      position = "auto", scale = 1, vrr = 0 })
    end
end
local function auto_monitors()           -- at start-up, on reload, and whenever a monitor is plugged in
    for _, m in ipairs(hl.get_monitors({ all = true }) or {}) do auto_monitor(m) end
end
auto_monitors()
hl.on("monitor.added", auto_monitors)

---- AUTOSTART ----
-- waybar and the paleOS shell (panels + password dialog) run as systemd user services so
-- they restart if they crash; these small helpers just start with the session.
hl.on("hyprland.start", function()
    hl.exec_cmd("mako")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
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
    dwindle = { preserve_split = true },
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
dofile(home .. "/.config/hypr/bindings.lua")

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

