import QtQuick
import "arch.js" as Arch

// Arch constellation: the logo as stars joined by faint lines, slowly breathing and drifting,
// over a twinkling sky, with a light sweep passing through. One 30 fps clock.
Rectangle {
    id: root
    property bool running: true
    property real t: 20
    gradient: Gradient { GradientStop { position: 0; color: "#05060a" } GradientStop { position: 1; color: "#020203" } }
    Timer { interval: 33; repeat: true; running: root.running; onTriggered: root.t += 0.033 }

    // sparse subset of the logo = the constellation's stars
    readonly property var stars: Arch.points().filter((p, i) => i % 4 === 0)
    readonly property real logoH: height * 0.56
    readonly property real logoW: logoH * Arch.aspect

    Repeater {   // background sky
        model: 120
        delegate: Rectangle {
            readonly property real a: Math.random()
            readonly property real b: Math.random()
            x: a * root.width; y: b * root.height
            width: a > 0.93 ? 2 : 1; height: width; radius: width; color: "#ffffff"
            opacity: 0.06 + 0.25 * (0.5 + 0.5 * Math.sin(root.t * (0.5 + b) + a * 6.28))
        }
    }

    Item {
        id: shape
        width: root.logoW; height: root.logoH
        x: (root.width - width) / 2 + Math.sin(root.t * 0.05) * 30
        y: (root.height - height) / 2 + Math.cos(root.t * 0.04) * 20
        rotation: Math.sin(root.t * 0.03) * 2.5

        Canvas {   // faint lines between neighbouring stars (drawn once)
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative
            opacity: 0.5 + 0.5 * Math.sin(root.t * 0.25)
            onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
            onPaint: {
                const g = getContext("2d"); g.reset(); if (width <= 0) return
                const s = root.stars, lim = 0.09
                g.strokeStyle = Qt.rgba(1, 1, 1, 0.07); g.lineWidth = 1
                for (let i = 0; i < s.length; i++) for (let j = i + 1; j < s.length; j++) {
                    const dx = (s[i].x - s[j].x) * Arch.aspect, dy = s[i].y - s[j].y
                    if (dx * dx + dy * dy < lim * lim) { g.beginPath(); g.moveTo(s[i].x * width, s[i].y * height); g.lineTo(s[j].x * width, s[j].y * height); g.stroke() }
                }
            }
        }
        Repeater {
            model: root.stars.length
            delegate: Rectangle {
                required property int index
                readonly property var p: root.stars[index]
                // a light sweep moves diagonally through the logo every ~12 s
                readonly property real sweep: Math.max(0, 1 - Math.abs((p.x + p.y) - ((root.t * 0.18) % 3 - 0.5)) * 4)
                width: 2.5 + p.d * 2 + sweep * 2; height: width; radius: width
                x: p.x * shape.width - width / 2; y: p.y * shape.height - height / 2
                color: "#ffffff"
                opacity: 0.35 + 0.35 * (0.5 + 0.5 * Math.sin(root.t * (0.7 + p.d) + index)) + sweep * 0.3
            }
        }
    }
}
