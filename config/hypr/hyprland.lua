-- paleOS — Hyprland config. Docs: https://wiki.hypr.land/
-- Your own files, loaded below:  monitors.lua (displays) · bindings.lua (keys)

local home = os.getenv("HOME")
dofile(home .. "/.config/hypr/monitors.lua")

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
    render = { direct_scanout = 2 },           -- fullscreen games bypass the compositor
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

hl.window_rule({ name = "screensaver", match = { class = "^screensaver$" }, fullscreen = true, no_anim = true })

-- Alt-Tab out of a fullscreen game: the other window takes over fullscreen;
-- switching back gives the game its fullscreen again (default would drop it).
hl.config({ misc = { on_focus_under_fullscreen = 1 } })

---- CUSTOMIZE ----
-- Gaps, rounding and animations from the Customize app (SUPER+SPACE → Customize).
pcall(dofile, home .. "/.config/hypr/paleos.lua")

hl.window_rule({ name = "customize", match = { title = "^Customize — paleOS$" }, float = true, center = true, size = "820 860" })
