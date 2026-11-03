import QtQuick

// Snow: flakes at three depths — small and slow far away, large soft out-of-focus flakes up close.
Rectangle {
    id: root
    property bool running: true
    property int fps: 30
    property real speed: 1
    property real detail: 1
    property real t: 20
    Timer { interval: Math.round(1000 / Math.max(5, root.fps)); repeat: true; running: root.running; onTriggered: root.t += root.speed * interval / 1000 }
    gradient: Gradient { GradientStop { position: 0; color: "#06070a" } GradientStop { position: 1; color: "#0e1014" } }
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
        model: Math.round(150 * root.detail)
        delegate: Item {
            readonly property real depth: Math.pow(Math.random(), 1.8)          // most flakes are far away
            readonly property real x0: Math.random()
            readonly property real y0: Math.random()
            readonly property real fall: 14 + depth * 70
            readonly property real size: 1.5 + depth * 9
            x: x0 * root.width + Math.sin(root.t * (0.3 + depth * 0.6) + x0 * 20) * (5 + depth * 20) - size / 2
            y: (y0 * (root.height + 40) + root.t * fall) % (root.height + 40) - 20 - size / 2
            width: size; height: size
            opacity: depth > 0.7 ? 0.35 : 0.25 + depth * 0.5
            Glow { anchors.fill: parent; visible: depth > 0.6; strength: 0.9 }             // near: soft bokeh
            Rectangle { anchors.fill: parent; visible: depth <= 0.6; radius: width; color: "white" }
        }
    }
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: parent.height * 0.25
        gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "#14161b" } } }
}
