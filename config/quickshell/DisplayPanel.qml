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
        if (p.queued.length) { const next = p.queued; p.queued = []; Qt.callLater(() => { apply.command = next; apply.running = true }) } else settle.restart()
    } }
    property var queued: []
    function run(args) {             // a change made while another is still applying waits for it
        if (apply.running) { queued = [p.tool].concat(args); return }
        apply.command = [p.tool].concat(args); apply.running = true
    }
    Timer { id: settle; interval: 600; onTriggered: p.refresh() }
    function setMode(resolution, hz) { p.run(["set", "mode", resolution + "@" + hz]) }

    Timer { interval: 1000; repeat: true; running: p.open && p.mon && p.mon.confirmSeconds > 0; onTriggered: p.refresh() }
    Heading { visible: p.mon && p.mon.confirmSeconds > 0; text: "KEEP THESE SETTINGS?"; value: p.mon ? p.mon.confirmSeconds + " s" : "" }
    Entry { visible: p.mon && p.mon.confirmSeconds > 0; text: "Keep display settings"; onClicked: p.run(["confirm"]) }
    Entry { visible: p.mon && p.mon.confirmSeconds > 0; text: "Revert now"; onClicked: p.run(["revert"]) }

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

    // scale: drag freely; the label shows the nearest scale Hyprland supports on this monitor
    // (whole-pixel ones only, from `display scales`), applied when you let go
    function nearest(v) { return scales.reduce((a, b) => Math.abs(b - v) < Math.abs(a - v) ? b : a) }
    readonly property real minScale: scales[0]
    readonly property real maxScale: scales[scales.length - 1]
    property real dragPos: -1             // handle position while dragging (follows the mouse, not the snap)
    function scalePos(v) { return maxScale > minScale ? (v - minScale) / (maxScale - minScale) : 0 }
    function applyScaleNow() {
        if (p.mon && Math.abs(p.pending - p.mon.scale) > 0.001) p.run(["set", "scale", String(p.pending)])
    }
    Timer { id: applyScale; interval: 600; onTriggered: p.applyScaleNow() }
    Heading { text: "SCALE"; value: (+p.pending.toFixed(2)) + "x" }
    Level {
        accessibleName: "Display scale"
        value: p.dragPos >= 0 ? p.dragPos : p.scalePos(p.pending)
        onMoved: v => {
            if (dragging) {
                p.dragPos = v
                p.pending = p.nearest(p.minScale + v * (p.maxScale - p.minScale))
            } else {                   // scroll wheel: one supported scale per notch, applied after a short pause
                const pos = p.scalePos(p.pending), dir = v > pos + 0.001 ? 1 : v < pos - 0.001 ? -1 : 0
                const i = p.scales.indexOf(p.nearest(p.pending)) + dir
                p.pending = p.scales[Math.max(0, Math.min(p.scales.length - 1, i))]
                applyScale.restart()
            }
        }
        onReleased: { p.dragPos = -1; applyScale.stop(); p.applyScaleNow() }
    }

    // HDR is never switched on by apps (cm_auto_hdr = 0); it's on all the time or off all the time
    Heading { text: "HDR" }
    Switcher {
        text: p.mon && p.mon.hdrSupported ? "HDR (always on)" : "HDR unavailable on this monitor"
        enabled: p.mon && (p.mon.hdrSupported || p.mon.hdr)
        checked: p.mon ? p.mon.hdr : false
        onToggled: p.run(["set", "hdr", p.mon && p.mon.hdr ? "off" : "on"])
    }
    // brightness of normal (non-HDR) content while HDR is on, applied when you let go
    property int sdrPending: 250
    onMonChanged: if (mon && mon.sdr) sdrPending = mon.sdr
    Timer { id: applySdr; interval: 450
        onTriggered: if (p.mon && p.sdrPending !== p.mon.sdr) p.run(["set", "sdr", String(p.sdrPending)]) }
    Heading { visible: p.mon && p.mon.hdr; text: "SDR BRIGHTNESS"; value: p.sdrPending + " nits" }
    Level {
        accessibleName: "SDR brightness"
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
