import QtQuick
import Quickshell
import Quickshell.Io

Panel {
    id: p
    property var mon: null            // first monitor from hyprctl
    property var rates: []
    property bool night: false
    readonly property string file: Quickshell.env("HOME") + "/.config/hypr/monitors.lua"

    title: "Display"
    glyph: 0xF0379
    subtitle: mon ? mon.name + " · " + mon.width + "×" + mon.height : ""

    function refresh() { info.running = true; nl.running = true }
    onOpenChanged: if (open) refresh()

    Process {   // current monitor + available refresh rates
        id: info
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector { onStreamFinished: {
            const m = JSON.parse(this.text)[0]; p.mon = m; p.pending = m.scale
            const r = m.availableModes.filter(x => x.startsWith(m.width + "x" + m.height + "@"))
                       .map(x => Math.round(parseFloat(x.split("@")[1])))
            p.rates = [...new Set(r)].filter(x => x >= 60).sort((a, b) => b - a).slice(0, 4).map(String)
        } }
    }
    Process { id: nl; command: ["pgrep", "-x", "hyprsunset"]; onExited: code => p.night = code === 0 }
    Process { id: apply; onExited: p.refresh() }
    function set(key, value) {   // edit monitors.lua (first monitor block) and reload
        const re = key === "mode" ? `0,/mode     = "[0-9]+x[0-9]+@[0-9]+"/s//mode     = "${value}"/`
                                  : `0,/scale    = [0-9.]+,/s//scale    = ${value},/`
        apply.command = ["bash", "-c", `sed -i -E '${re}' "${p.file}" && hyprctl reload >/dev/null`]
        apply.running = true
    }

    // valid scales for this screen; the slider snaps to them and applies when you let go
    readonly property var scales: [1, 1.2, 1.25, 1.5, 1.6, 2]
    property real pending: mon ? mon.scale : 1
    function nearest(v) { return scales.reduce((a, b) => Math.abs(b - v) < Math.abs(a - v) ? b : a) }
    Timer { id: applyScale; interval: 450; onTriggered: if (p.mon && p.pending !== p.mon.scale) p.set("scale", String(p.pending)) }

    Heading { text: "SCALE"; value: (+p.pending.toFixed(2)) + "x" }
    Level {
        value: (p.pending - 1) / 1
        onMoved: v => { p.pending = p.nearest(1 + v); applyScale.restart() }
    }


    Heading { text: "NIGHT LIGHT" }
    Switcher {
        text: "Warm colors"
        checked: p.night
        onToggled: { Quickshell.execDetached(["bash", "-c", "~/.local/bin/toggle-nightlight"]); p.night = !p.night }
    }

    Heading { text: "SETTINGS" }
    Entry {
        glyph: 0xF03EB
        text: "Open display settings file"
        onClicked: { Quickshell.execDetached(["foot", "-e", "nvim", p.file]); p.closeRequested() }
    }
}
