import QtQuick

// Night sky: drifting clouds in three layers, twinkling stars, the odd shooting star.
Rectangle {
    id: root
    property bool running: true
    property int fps: 30
    property real speed: 1
    property real detail: 1
    property real t: 20
    Timer { interval: Math.round(1000 / Math.max(5, root.fps)); repeat: true; running: root.running; onTriggered: root.t += root.speed * interval / 1000 }
    // Sizes follow the largest 16:9 area that fits (fh = its height, fw = its width), so nothing stretches
    // or runs off an ultrawide or portrait screen; `more` = how much extra screen there is around it.
    readonly property real fh: Math.min(height, width * 9 / 16)
    readonly property real fw: fh * 16 / 9
    readonly property real more: fh > 0 ? Math.min(4, width * height / (fw * fh)) : 1   // capped: sizes are odd while the window opens
    gradient: Gradient { GradientStop { position: 0.0; color: "#06070b" } GradientStop { position: 1.0; color: "#020203" } }

    Repeater {
        model: Math.round(110 * root.detail * root.more)
        delegate: Rectangle {
            readonly property real r: Math.random()
            readonly property real q: Math.random()
            x: q * root.width; y: r * root.height * 0.85
            width: r > 0.92 ? 1.8 : 1; height: width; radius: width; color: "#ffffff"
            opacity: 0.06 + (0.25 + 0.35 * q) * (0.5 + 0.5 * Math.sin(root.t * (0.6 + r) + q * 6.28))
        }
    }
    component Clouds: Item {
        id: cl
        property real alpha: 0.02
        property real px: 20
        property real bandTop: 0
        property real band: 0.5
        width: root.width * 2; height: root.height
        x: -((root.t * px) % root.width)
        Canvas {
            anchors.fill: parent; renderStrategy: Canvas.Cooperative
            onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
            onPaint: {
                const g = getContext("2d"), W = root.width; g.reset(); if (W <= 0 || root.fw <= 0) return
                for (let i = 0; i < 70 * Math.min(4, W / root.fw); i++) {
                    const x = Math.random() * W, y = (cl.bandTop + Math.random() * cl.band) * height, r = root.fw * (0.04 + Math.random() * 0.12)
                    for (const dx of [0, W]) {
                        const gr = g.createRadialGradient(x + dx, y, 0, x + dx, y, r)
                        gr.addColorStop(0, Qt.rgba(0.74, 0.79, 0.92, cl.alpha)); gr.addColorStop(1, Qt.rgba(0.74, 0.79, 0.92, 0))
                        g.fillStyle = gr; g.beginPath(); g.ellipse(x + dx - r * 1.6, y - r * 0.55, r * 3.2, r * 1.1); g.fill()
                    }
                }
            }
        }
    }
    Clouds { alpha: 0.014; px: 10; bandTop: 0.0; band: 0.5 }
    Clouds { alpha: 0.020; px: 20; bandTop: 0.3; band: 0.5 }
    Clouds { alpha: 0.026; px: 34; bandTop: 0.6; band: 0.45 }

    Item {   // shooting star
        id: meteor
        property real start: -100
        property real sx: 0
        property real sy: 0
        property real len: 500
        readonly property real p: (root.t - start) / 0.9
        visible: p >= 0 && p <= 1
        x: sx + Math.cos(rotation * Math.PI / 180) * len * p * p
        y: sy + Math.sin(rotation * Math.PI / 180) * len * p * p
        opacity: p < 0.2 ? p * 4 : (1 - p) * 1.0
        width: 150; height: 1.5
        Rectangle { anchors.fill: parent; radius: 1
            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "#ddffffff" } } }
        Timer {
            interval: 7000; repeat: true; running: root.running
            onTriggered: {
                interval = (5000 + Math.random() * 12000) / Math.max(0.25, root.speed)
                meteor.rotation = 20 + Math.random() * 25; meteor.sx = Math.random() * root.width * 0.8
                meteor.sy = Math.random() * root.height * 0.4; meteor.len = root.fw * (0.15 + Math.random() * 0.2); meteor.start = root.t
            }
        }
    }
}
