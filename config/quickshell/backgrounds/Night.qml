import QtQuick

// Night sky: drifting clouds, twinkling stars, the odd shooting star.
// Driven by one clock at 30 fps (not the monitor's refresh rate), and fully stopped
// while `running` is false — no CPU/GPU use when you can't see it.
Rectangle {
    id: sky
    property bool running: true
    property real t: 20                         // seconds of animation (starts a little way in)
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#06070a" }
        GradientStop { position: 1.0; color: "#020203" }
    }

    Timer {
        interval: 33; repeat: true; running: sky.running
        onTriggered: sky.t += 0.033
    }

    Repeater {   // stars twinkle on the shared clock
        model: 90
        delegate: Rectangle {
            readonly property real r: Math.random()
            readonly property real q: Math.random()
            x: q * sky.width; y: r * sky.height * 0.8
            width: r > 0.9 ? 2 : 1; height: width; radius: width
            color: "#ffffff"
            opacity: 0.08 + (0.3 + 0.35 * q) * (0.5 + 0.5 * Math.sin(sky.t * (0.6 + r) + q * 6.28))
        }
    }

    component Clouds: Item {
        id: layer
        property real alpha: 0.02
        property real speed: 20                 // pixels per second
        property real bandTop: 0
        property real band: 0.5
        width: sky.width * 2; height: sky.height
        x: -((sky.t * speed) % sky.width)
        Canvas {
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const g = getContext("2d"), W = sky.width
                g.reset(); if (W <= 0) return
                for (let i = 0; i < 80; i++) {   // cloud size scales with the sky, so small previews look the same
                    const x = Math.random() * W, y = (layer.bandTop + Math.random() * layer.band) * height, r = W * (0.04 + Math.random() * 0.125)
                    for (const dx of [0, W]) {          // drawn twice so the loop is seamless
                        const gr = g.createRadialGradient(x + dx, y, 0, x + dx, y, r)
                        gr.addColorStop(0, Qt.rgba(0.75, 0.8, 0.92, layer.alpha)); gr.addColorStop(1, Qt.rgba(0.75, 0.8, 0.92, 0))
                        g.fillStyle = gr; g.beginPath(); g.ellipse(x + dx - r * 1.6, y - r * 0.6, r * 3.2, r * 1.2); g.fill()
                    }
                }
            }
        }
    }
    Clouds { alpha: 0.014; speed: 12; bandTop: 0.0; band: 0.5 }   // far, slow
    Clouds { alpha: 0.020; speed: 22; bandTop: 0.3; band: 0.5 }
    Clouds { alpha: 0.026; speed: 38; bandTop: 0.6; band: 0.45 }  // near, faster

    Item {   // shooting star, also on the shared clock
        id: meteor
        property real start: -100               // when (in t) the current one started
        property real sx: 0
        property real sy: 0
        property real len: 500
        readonly property real p: (sky.t - start) / 0.9   // 0..1 while flying
        visible: p >= 0 && p <= 1
        rotation: 30
        x: sx + Math.cos(rotation * Math.PI / 180) * len * p * p
        y: sy + Math.sin(rotation * Math.PI / 180) * len * p * p
        opacity: p < 0.2 ? p / 0.2 * 0.8 : (1 - p) / 0.8 * 0.8
        width: 140; height: 1.5
        Rectangle {
            anchors.fill: parent; radius: 1
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "#ddffffff" } }
        }
        Timer {
            interval: 7000; repeat: true; running: sky.running
            onTriggered: {
                interval = 5000 + Math.random() * 12000
                meteor.rotation = 20 + Math.random() * 25
                meteor.sx = Math.random() * sky.width * 0.8; meteor.sy = Math.random() * sky.height * 0.4
                meteor.len = 300 + Math.random() * 350
                meteor.start = sky.t
            }
        }
    }
}
