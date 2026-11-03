import QtQuick

// Aurora: soft bands of pale light slowly flowing and breathing. One 30 fps clock; stops when not running.
Rectangle {
    id: root
    property bool running: true
    property real t: 20                 // starts a little way in, so the first frame isn't empty
    color: "#040507"
    Timer { interval: 33; repeat: true; running: root.running; onTriggered: root.t += 0.033 }

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

    Repeater {
        model: 7
        delegate: Glow {
            required property int index
            readonly property real ph: index * 1.7
            readonly property real k: 0.05 + index * 0.012
            width: root.width * 1.1; height: root.height * 0.45
            tint: index % 2 ? "#cfd9e6" : "#e8e8e8"
            strength: 0.16
            x: root.width * 0.5 - width / 2 + Math.sin(root.t * k * 1.3 + ph) * root.width * 0.22
            y: root.height * (0.0 + index * 0.06) + Math.sin(root.t * k * 2 + ph) * 50
            rotation: -10 + Math.sin(root.t * k + ph) * 7
            scale: 0.85 + 0.2 * Math.sin(root.t * k * 0.8 + ph)
            opacity: 0.55 + 0.45 * Math.sin(root.t * 0.35 + ph)
        }
    }
}
