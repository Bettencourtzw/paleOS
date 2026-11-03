import QtQuick
import Quickshell
import Quickshell.Io

// Power settings: power mode, what happens when idle, and the power actions.
Panel {
    id: p
    property string mode: ""
    readonly property var s: Settings.data
    title: "Power"
    glyph: 0xF0425
    subtitle: mode ? "Power mode · " + mode.replace("-", " ") : ""
    onOpenChanged: if (open) get.running = true

    Process { id: get; command: ["powerprofilesctl", "get"]; stdout: StdioCollector { onStreamFinished: p.mode = this.text.trim() } }
    Process { id: put; onExited: get.running = true }
    Process { id: apply; command: [Quickshell.env("HOME") + "/.local/bin/paleos-apply"] }
    function set(key, value) { s[key] = value; Settings.save(); apply.running = false; apply.running = true }

    Heading { text: "POWER MODE" }
    Choice {
        options: [{ label: "Performance", value: "performance" }, { label: "Balanced", value: "balanced" }, { label: "Saver", value: "power-saver" }]
        current: p.mode
        onPicked: v => { put.command = ["powerprofilesctl", "set", v]; put.running = true; p.mode = v }
    }

    Heading { text: "WHEN IDLE" }
    Text { text: "Screensaver after"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
    Choice { options: [0, 2, 5, 10, 20].map(m => ({ label: m ? m + "m" : "Off", value: m })); current: p.s.screensaverMinutes; onPicked: v => p.set("screensaverMinutes", v) }
    Text { text: "Lock after"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
    Choice { options: [0, 5, 10, 15, 30].map(m => ({ label: m ? m + "m" : "Off", value: m })); current: p.s.lockMinutes; onPicked: v => p.set("lockMinutes", v) }
    Text { text: "Sleep after"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
    Choice { options: [0, 15, 30, 60, 120].map(m => ({ label: m ? (m < 60 ? m + "m" : m / 60 + "h") : "Never", value: m })); current: p.s.suspendMinutes; onPicked: v => p.set("suspendMinutes", v) }

    Heading { text: "NOW" }
    Row {
        width: parent.width; spacing: 6
        Repeater {
            model: [ { g: 0xF033E, t: "Lock", c: ["loginctl", "lock-session"] }, { g: 0xF04B2, t: "Sleep", c: ["systemctl", "suspend"] },
                     { g: 0xF0709, t: "Restart", c: ["systemctl", "reboot"] }, { g: 0xF0425, t: "Shut down", c: ["systemctl", "poweroff"] } ]
            delegate: Rectangle {
                required property var modelData
                width: (parent.width - 18) / 4; height: 58; radius: 10
                color: ma.containsMouse ? Theme.hover : Theme.bgAlt; border.color: Theme.border
                Column { anchors.centerIn: parent; spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.icon(modelData.g); color: Theme.fg; font.family: Theme.font; font.pixelSize: 18 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.t; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10 } }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { p.closeRequested(); Quickshell.execDetached(modelData.c) } }
            }
        }
    }
}
