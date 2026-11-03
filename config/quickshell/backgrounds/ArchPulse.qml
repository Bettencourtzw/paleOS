import QtQuick

// Arch pulse — deep black. The Arch symbol breathing softly, thin orbit rings tilted around it
// with points travelling along them, and slow ripples of light.
Rectangle {
    id: root
    property bool running: true
    property int fps: 30
    property real speed: 1
    property real detail: 1
    property real t: 20
    Timer { interval: Math.round(1000 / Math.max(5, root.fps)); repeat: true; running: root.running; onTriggered: root.t += root.speed * interval / 1000 }
    color: "#000000"
    readonly property real s: Math.min(width, height)
    component Glow: Canvas {   // soft round glow, drawn once; moving/fading it later is free
        property color tint: "#ffffff"
        property real strength: 1.0
        renderStrategy: Canvas.Cooperative
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const g = getContext("2d"), r = Math.min(width, height) / 2
            g.reset(); if (r <= 0) return
            g.save(); g.scale(width / (2 * r), height / (2 * r))
            const gr = g.createRadialGradient(r, r, 0, r, r, r)
            gr.addColorStop(0, Qt.rgba(tint.r, tint.g, tint.b, strength))
            gr.addColorStop(0.35, Qt.rgba(tint.r, tint.g, tint.b, strength * 0.35))
            gr.addColorStop(1, Qt.rgba(tint.r, tint.g, tint.b, 0))
            g.fillStyle = gr; g.fillRect(0, 0, 2 * r, 2 * r); g.restore()
        }
    }

    Repeater {   // slow ripples
        model: 3
        delegate: Rectangle {
            required property int index
            readonly property real p: ((root.t / 9) + index / 3) % 1
            width: root.s * (0.32 + p * 0.8); height: width; radius: width / 2
            anchors.centerIn: parent
            color: "transparent"; border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07 * (1 - p) * Math.min(1, p * 5))
        }
    }
    Glow { anchors.centerIn: parent; width: root.s * 0.75; height: width; strength: 0.10
           scale: 0.92 + 0.08 * Math.sin(root.t * 0.7); opacity: 0.7 + 0.3 * Math.sin(root.t * 0.7) }

    Repeater {   // three tilted orbits, each with travelling points
        model: 3
        delegate: Item {
            id: orbit
            required property int index
            readonly property real rx: root.s * (0.30 + index * 0.05)
            readonly property real ry: rx * 0.34
            anchors.centerIn: parent
            width: rx * 2; height: ry * 2
            rotation: -35 + index * 40 + Math.sin(root.t * 0.05 + index) * 6
            Rectangle { anchors.fill: parent; radius: height / 2; color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.06) }
            Repeater {
                model: 2 + Math.round(root.detail)
                delegate: Item {
                    required property int index
                    readonly property real a: root.t * (0.35 + orbit.index * 0.07) * (orbit.index % 2 ? -1 : 1) + index * 6.28 / 3
                    x: orbit.rx + Math.cos(a) * orbit.rx; y: orbit.ry + Math.sin(a) * orbit.ry
                    Glow { x: -9; y: -9; width: 18; height: 18; strength: 0.5 }
                    Rectangle { x: -1.5; y: -1.5; width: 3; height: 3; radius: 2; color: "white"; opacity: 0.6 + 0.4 * Math.sin(a) }
                }
            }
        }
    }
    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(0xF08C7)        // Arch logo
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: root.s * 0.24
        color: "#ececec"
        opacity: 0.82 + 0.18 * Math.sin(root.t * 0.7)
    }
}
