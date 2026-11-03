import QtQuick
import Quickshell
import Quickshell.Io

// Display panel: scale slider + night light. Uses ~/.local/bin/display for the focused monitor.
Panel {
    id: p
    property var mon: null
    property var scales: [1]
    property real pending: 1
    property bool night: false
    readonly property string tool: Quickshell.env("HOME") + "/.local/bin/display"

    title: "Display"
    glyph: 0xF0379
    subtitle: mon ? mon.name + " · " + mon.width + "×" + mon.height : ""
    onOpenChanged: if (open) { info.running = true; sc.running = true; nl.running = true }

    Process { id: info; command: [p.tool, "info"]
        stdout: StdioCollector { onStreamFinished: { p.mon = JSON.parse(this.text); p.pending = p.mon.scale } } }
    Process { id: sc; command: [p.tool, "scales"]
        stdout: StdioCollector { onStreamFinished: p.scales = this.text.trim().split("\n").map(Number) } }
    Process { id: nl; command: ["pgrep", "-x", "hyprsunset"]; onExited: code => p.night = code === 0 }
    Process { id: apply }

    // the slider snaps to sharp scales and applies when you let go
    function nearest(v) { return scales.reduce((a, b) => Math.abs(b - v) < Math.abs(a - v) ? b : a) }
    readonly property real maxScale: scales[scales.length - 1]
    Timer { id: applyScale; interval: 450
        onTriggered: if (p.mon && p.pending !== p.mon.scale) { apply.command = [p.tool, "set", "scale", String(p.pending)]; apply.running = true; p.mon.scale = p.pending } }

    Heading { text: "SCALE"; value: (+p.pending.toFixed(2)) + "x" }
    Level {
        value: p.maxScale > 1 ? (p.pending - 1) / (p.maxScale - 1) : 0
        onMoved: v => { p.pending = p.nearest(1 + v * (p.maxScale - 1)); applyScale.restart() }
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
