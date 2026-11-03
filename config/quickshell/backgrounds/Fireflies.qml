import QtQuick

// Fireflies: soft glowing points floating and pulsing. One 30 fps clock; stops when not running.
Rectangle {
    id: root
    property bool running: true
    property real t: 20                 // starts a little way in, so the first frame isn't empty
    color: "#040405"
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
        model: 34
        delegate: Item {
            readonly property real a: Math.random() * 6.28
            readonly property real b: Math.random() * 6.28
            readonly property real cx: Math.random()
            readonly property real cy: Math.random()
            readonly property real sp: 0.05 + Math.random() * 0.08
            readonly property real size: 40 + Math.random() * 60
            x: root.width * cx + Math.sin(root.t * sp + a) * 120 - size / 2
            y: root.height * cy + Math.cos(root.t * sp * 1.3 + b) * 90 - size / 2
            width: size; height: size
            opacity: 0.15 + 0.85 * Math.max(0, Math.sin(root.t * (0.3 + sp) + a))
            Glow { anchors.fill: parent; tint: "#f2f0e6"; strength: 0.35 }
            Rectangle { anchors.centerIn: parent; width: 2.5; height: 2.5; radius: 2; color: "#ffffff" }
        }
    }
}
