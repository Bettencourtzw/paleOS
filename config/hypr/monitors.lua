-- Display settings. Opened from: SUPER+SPACE -> Display -> Open display settings file
-- Docs: https://wiki.hypr.land/configuring/core/monitors/
-- Example for a 1920x1080 260 Hz monitor on DP-1:
--   hl.monitor({ output = "DP-1", mode = "1920x1080@260", position = "0x0", scale = 1, vrr = 0 })
-- vrr = 0 : FreeSync off (vrr = 2, "only in fullscreen", makes many monitors flash black when a window goes fullscreen)
hl.monitor({
    output   = "",
    mode     = "highrr",
    position = "auto",
    scale    = 1,
    vrr      = 0,
})
