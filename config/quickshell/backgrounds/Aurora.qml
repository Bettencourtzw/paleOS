import QtQuick

// Aurora: curtains of pale light — many tall soft streaks along slowly moving curves, shimmering.
Rectangle {
    id: root
    property bool running: true
    property int fps: 30
    property real speed: 1
    property real detail: 1
    property real t: 20
    Timer { interval: Math.round(1000 / Math.max(5, root.fps)); repeat: true; running: root.running; onTriggered: root.t += root.speed * interval / 1000 }
    gradient: Gradient { GradientStop { position: 0; color: "#05070b" } GradientStop { position: 0.6; color: "#030406" } GradientStop { position: 1; color: "#010101" } }
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

    Repeater {   // a few stars
        model: Math.round(60 * root.detail)
        delegate: Rectangle {
            readonly property real a: Math.random()
            readonly property real b: Math.random()
            x: a * root.width; y: b * root.height * 0.7; width: 1; height: 1; color: "white"
            opacity: 0.05 + 0.15 * (0.5 + 0.5 * Math.sin(root.t * (0.4 + b) + a * 6))
        }
    }
    Repeater {   // two curtains of streaks
        model: 2
        delegate: Item {
            id: curtain
            required property int index
            anchors.fill: parent
            readonly property int n: Math.round(28 * root.detail)
            Repeater {
                model: curtain.n
                delegate: Glow {
                    required property int index
                    readonly property real u: index / curtain.n                       // 0..1 across the screen
                    readonly property real wave: Math.sin(u * 5 + root.t * 0.18 + curtain.index * 2) * 0.5 + Math.sin(u * 11 - root.t * 0.11) * 0.25
                    tint: curtain.index ? "#d4e2ef" : "#e9ecef"
                    strength: 0.11
                    width: root.width * 0.16; height: root.height * (0.45 + 0.15 * Math.sin(u * 7 + root.t * 0.3))
                    x: u * root.width * 1.15 - root.width * 0.12
                    y: root.height * (0.08 + curtain.index * 0.1) + wave * root.height * 0.08
                    opacity: 0.45 + 0.55 * Math.sin(u * 3.5 + root.t * (0.35 + curtain.index * 0.12))
                }
            }
        }
    }
    Rectangle {   // fade into the dark ground
        anchors.fill: parent
        gradient: Gradient { GradientStop { position: 0.5; color: "transparent" } GradientStop { position: 1; color: "#010101" } }
    }
}
