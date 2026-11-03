import QtQuick
import Quickshell
import Quickshell.Io

// Display panel: resolution + refresh rate, scale, HDR, night light. Uses ~/.local/bin/display (focused monitor).
Panel {
    id: p
    property var mon: null
    property var modes: []                 // [{ resolution, rates: [..] }]
    property var scales: [1]
    property real pending: 1
    property bool night: false
    property string res: ""
    readonly property string tool: Quickshell.env("HOME") + "/.local/bin/display"
    readonly property var resList: modes.map(m => m.resolution)
    readonly property var rateList: (modes.find(m => m.resolution === res) || { rates: [] }).rates.map(r => r + " Hz")

    title: "Display"
    glyph: 0xF0379
    subtitle: mon ? mon.name + " · " + mon.width + "×" + mon.height + " @ " + Math.round(mon.refreshRate) + " Hz" : ""
    onOpenChanged: if (open) refresh()
    function refresh() { info.running = true; md.running = true; sc.running = true; nl.running = true }

    Process { id: info; command: [p.tool, "info"]
        stdout: StdioCollector { onStreamFinished: { p.mon = JSON.parse(this.text); p.pending = p.mon.scale; p.res = p.mon.width + "x" + p.mon.height } } }
    Process { id: md; command: [p.tool, "modes"]; stdout: StdioCollector { onStreamFinished: p.modes = JSON.parse(this.text) } }
    Process { id: sc; command: [p.tool, "scales"]; stdout: StdioCollector { onStreamFinished: p.scales = this.text.trim().split("\n").map(Number) } }
    Process { id: nl; command: ["pgrep", "-x", "hyprsunset"]; onExited: code => p.night = code === 0 }
    Process { id: apply; onExited: code => {
        if (code !== 0) Quickshell.execDetached(["notify-send", "Display settings", "Could not update the monitor settings. Check monitors.lua."])
        settle.restart()
    } }
    Timer { id: settle; interval: 600; onTriggered: p.refresh() }
    function setMode(resolution, hz) { apply.command = [p.tool, "set", "mode", resolution + "@" + hz]; apply.running = true }

    Heading { text: "RESOLUTION" }
    Dropdown {
        model: p.resList
        currentIndex: p.resList.indexOf(p.res)
        onActivated: i => {   // new resolution: use its highest refresh rate
            const m = p.modes[i]; p.res = m.resolution; p.setMode(m.resolution, m.rates[0])
        }
    }

    Heading { text: "REFRESH RATE" }
    Dropdown {
        model: p.rateList
        currentIndex: p.mon ? p.rateList.indexOf(Math.round(p.mon.refreshRate) + " Hz") : -1
        onActivated: i => p.setMode(p.res, parseInt(p.rateList[i]))
    }

    // scale snaps to sharp values and applies when you let go
    function nearest(v) { return scales.reduce((a, b) => Math.abs(b - v) < Math.abs(a - v) ? b : a) }
    readonly property real maxScale: scales[scales.length - 1]
    Timer { id: applyScale; interval: 450
        onTriggered: if (p.mon && p.pending !== p.mon.scale) { apply.command = [p.tool, "set", "scale", String(p.pending)]; apply.running = true } }
    Heading { text: "SCALE"; value: (+p.pending.toFixed(2)) + "x" }
    Level {
        value: p.maxScale > 1 ? (p.pending - 1) / (p.maxScale - 1) : 0
        onMoved: v => { p.pending = p.nearest(1 + v * (p.maxScale - 1)); applyScale.restart() }
    }

    // HDR is never switched on by apps (cm_auto_hdr = 0); it's on all the time or off all the time
    Heading { text: "HDR" }
    Switcher {
        text: "HDR (always on)"
        checked: p.mon ? p.mon.hdr : false
        onToggled: { apply.command = [p.tool, "set", "hdr", p.mon && p.mon.hdr ? "off" : "on"]; apply.running = true }
    }
    // brightness of normal (non-HDR) content while HDR is on, applied when you let go
    property int sdrPending: 250
    onMonChanged: if (mon && mon.sdr) sdrPending = mon.sdr
    Timer { id: applySdr; interval: 450
        onTriggered: if (p.mon && p.sdrPending !== p.mon.sdr) { apply.command = [p.tool, "set", "sdr", String(p.sdrPending)]; apply.running = true } }
    Heading { visible: p.mon && p.mon.hdr; text: "SDR BRIGHTNESS"; value: p.sdrPending + " nits" }
    Level {
        visible: p.mon && p.mon.hdr
        value: (p.sdrPending - 80) / 320
        onMoved: v => { p.sdrPending = Math.round((80 + v * 320) / 10) * 10; applySdr.restart() }
    }

    Heading { text: "NIGHT LIGHT" }
    Switcher {
        text: "Warm colors"
        checked: p.night
        onToggled: { Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/toggle-nightlight"]); p.night = !p.night }
    }

    Heading { text: "SETTINGS" }
    Entry {
        glyph: 0xF03EB
        text: "Open display settings file"
        onClicked: { Quickshell.execDetached(["foot", "-e", "nvim", Quickshell.env("HOME") + "/.config/hypr/monitors.lua"]); p.closeRequested() }
    }
}
