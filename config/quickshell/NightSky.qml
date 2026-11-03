import QtQuick

// Calm animated night sky: drifting clouds, twinkling stars, the odd shooting star.
// Everything stops (no CPU/GPU use) while `running` is false.
Rectangle {
    id: sky
    property bool running: true
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#06070a" }
        GradientStop { position: 1.0; color: "#020203" }
    }

    Repeater {   // stars
        model: 90
        delegate: Rectangle {
            readonly property real r: Math.random()
            readonly property real q: Math.random()
            x: q * sky.width; y: r * sky.height * 0.8
            width: r > 0.9 ? 2 : 1; height: width; radius: width
            color: "#ffffff"; opacity: 0.2
            SequentialAnimation on opacity {
                loops: Animation.Infinite; paused: !sky.running
                NumberAnimation { to: 0.35 + 0.3 * q; duration: 2500 + r * 4000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.05; duration: 2500 + q * 4000; easing.type: Easing.InOutSine }
            }
        }
    }

    component Clouds: Item {
        id: layer
        property real alpha: 0.02
        property int seconds: 300
        property real bandTop: 0
        property real band: 0.5
        width: sky.width * 2; height: sky.height
        Canvas {
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative
            onPaint: {
                const g = getContext("2d"), W = sky.width
                for (let i = 0; i < 80; i++) {
                    const x = Math.random() * W, y = (layer.bandTop + Math.random() * layer.band) * height, r = 80 + Math.random() * 240
                    for (const dx of [0, W]) {
                        const gr = g.createRadialGradient(x + dx, y, 0, x + dx, y, r)
                        gr.addColorStop(0, Qt.rgba(0.75, 0.8, 0.92, layer.alpha)); gr.addColorStop(1, Qt.rgba(0.75, 0.8, 0.92, 0))
                        g.fillStyle = gr; g.beginPath(); g.ellipse(x + dx - r * 1.6, y - r * 0.6, r * 3.2, r * 1.2); g.fill()
                    }
                }
            }
        }
        NumberAnimation on x { from: 0; to: -sky.width; duration: layer.seconds * 1000; loops: Animation.Infinite; paused: !sky.running }
    }
    Clouds { alpha: 0.012; seconds: 480; bandTop: 0.0; band: 0.5 }
    Clouds { alpha: 0.018; seconds: 300; bandTop: 0.3; band: 0.5 }
    Clouds { alpha: 0.024; seconds: 180; bandTop: 0.6; band: 0.45 }

    Item {   // shooting star
        id: meteor
        width: 140; height: 1.5; opacity: 0
        Rectangle {
            anchors.fill: parent; radius: 1
            gradient: Gradient { orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "#ddffffff" } }
        }
        ParallelAnimation {
            id: fly
            NumberAnimation { id: fx; target: meteor; property: "x"; duration: 900; easing.type: Easing.InQuad }
            NumberAnimation { id: fy; target: meteor; property: "y"; duration: 900; easing.type: Easing.InQuad }
            SequentialAnimation {
                NumberAnimation { target: meteor; property: "opacity"; from: 0; to: 0.8; duration: 200 }
                NumberAnimation { target: meteor; property: "opacity"; to: 0; duration: 700 }
            }
        }
        Timer {
            interval: 8000; repeat: true; running: sky.running
            onTriggered: {
                interval = 6000 + Math.random() * 14000
                meteor.rotation = 20 + Math.random() * 25
                const a = meteor.rotation * Math.PI / 180, d = 300 + Math.random() * 350
                fx.from = Math.random() * sky.width * 0.8; fx.to = fx.from + Math.cos(a) * d
                fy.from = Math.random() * sky.height * 0.4; fy.to = fy.from + Math.sin(a) * d
                fly.restart()
            }
        }
    }
}
