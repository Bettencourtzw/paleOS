import QtQuick

// Fireflies: soft glowing points floating and pulsing above a dark meadow haze.
Rectangle {
    id: root
    property bool running: true
    property int fps: 30
    property real speed: 1
    property real detail: 1
    property real t: 20
    Timer { interval: Math.round(1000 / Math.max(5, root.fps)); repeat: true; running: root.running; onTriggered: root.t += root.speed * interval / 1000 }
    gradient: Gradient { GradientStop { position: 0; color: "#030304" } GradientStop { position: 1; color: "#08090a" } }
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
        model: Math.round(38 * root.detail)
        delegate: Item {
            readonly property real a: Math.random() * 6.28
            readonly property real b: Math.random() * 6.28
            readonly property real cx: Math.random()
            readonly property real cy: 0.25 + Math.random() * 0.75
            readonly property real sp: 0.05 + Math.random() * 0.08
            readonly property real size: root.height * (0.035 + Math.random() * 0.05)
            x: root.width * cx + Math.sin(root.t * sp + a) * root.width * 0.06 - size / 2
            y: root.height * cy + Math.cos(root.t * sp * 1.3 + b) * root.height * 0.08 - size / 2
            width: size; height: size
            opacity: 0.1 + 0.9 * Math.max(0, Math.sin(root.t * (0.3 + sp) + a))
            Glow { anchors.fill: parent; tint: "#f3f0e2"; strength: 0.4 }
            Rectangle { anchors.centerIn: parent; width: 2.5; height: 2.5; radius: 2; color: "#ffffff" }
        }
    }
}
