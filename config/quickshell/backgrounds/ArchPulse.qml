import QtQuick

// Arch pulse: the Arch symbol, a soft breathing glow, light rings flowing outward and a few
// points orbiting. One 30 fps clock; stops when not running.
Rectangle {
    id: root
    property bool running: true
    property real t: 20
    color: "#040405"
    Timer { interval: 33; repeat: true; running: root.running; onTriggered: root.t += 0.033 }
    readonly property real s: Math.min(width, height)       // scales with the screen (or preview)

    component Glow: Canvas {
        property real strength: 0.2
        renderStrategy: Canvas.Cooperative
        onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
        onPaint: {
            const g = getContext("2d"), r = width / 2; g.reset(); if (r <= 0) return
            const gr = g.createRadialGradient(r, r, 0, r, r, r)
            gr.addColorStop(0, Qt.rgba(1, 1, 1, strength)); gr.addColorStop(0.4, Qt.rgba(1, 1, 1, strength * 0.3)); gr.addColorStop(1, Qt.rgba(1, 1, 1, 0))
            g.fillStyle = gr; g.fillRect(0, 0, width, height)
        }
    }

    Repeater {   // rings flowing outward
        model: 4
        delegate: Rectangle {
            required property int index
            readonly property real p: ((root.t / 7) + index / 4) % 1
            width: root.s * (0.25 + p * 0.9); height: width; radius: width / 2
            anchors.centerIn: parent
            color: "transparent"; border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12 * (1 - p) * Math.min(1, p * 6))
        }
    }
    Glow {
        anchors.centerIn: parent
        width: root.s * 0.7; height: width
        strength: 0.16
        scale: 0.9 + 0.12 * Math.sin(root.t * 0.8)
        opacity: 0.6 + 0.4 * Math.sin(root.t * 0.8)
    }
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.s * 0.01
        text: String.fromCodePoint(0xF303)                   // Arch logo (Nerd Font)
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: root.s * 0.26
        color: "#e6e6e6"
        opacity: 0.75 + 0.25 * Math.sin(root.t * 0.8)
    }
    Repeater {   // orbiting points
        model: 7
        delegate: Rectangle {
            required property int index
            readonly property real r: root.s * (0.24 + index * 0.025)
            readonly property real a: root.t * (0.25 + index * 0.04) * (index % 2 ? -1 : 1) + index * 0.9
            width: 3; height: 3; radius: 2; color: "#ffffff"
            x: root.width / 2 + Math.cos(a) * r - 1.5
            y: root.height / 2 + Math.sin(a) * r * 0.95 - 1.5
            opacity: 0.3 + 0.5 * (0.5 + 0.5 * Math.sin(root.t + index))
        }
    }
}
