import QtQuick
import QtQuick.Shapes

// Waves: fine lines drifting like a slow topographic map, brighter in the middle, fading at the edges.
Rectangle {
    id: root
    property bool running: true
    property int fps: 30
    property real speed: 1
    property real detail: 1
    property real t: 20
    Timer { interval: Math.round(1000 / Math.max(5, root.fps)); repeat: true; running: root.running; onTriggered: root.t += root.speed * interval / 1000 }
    color: "#040405"
    Repeater {
        model: Math.round(16 * root.detail)
        delegate: Shape {
            id: line
            required property int index
            readonly property int count: Math.round(16 * root.detail)
            readonly property real u: index / Math.max(1, count - 1)
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real baseY: root.height * (0.15 + u * 0.7)
            readonly property real amp: root.height * (0.025 + 0.02 * Math.sin(u * 3.1))
            ShapePath {
                strokeColor: Qt.rgba(1, 1, 1, 0.035 + 0.075 * Math.sin(line.u * Math.PI))
                strokeWidth: 1.2
                fillColor: "transparent"
                PathPolyline {
                    path: {
                        const pts = [], n = 64, w = root.width
                        for (let i = 0; i <= n; i++) {
                            const x = w * i / n
                            const y = line.baseY
                                + Math.sin(i / n * 6.28 * 1.3 + root.t * 0.3 + line.index * 0.45) * line.amp
                                + Math.sin(i / n * 6.28 * 0.45 - root.t * 0.17 + line.index * 0.8) * line.amp * 0.7
                            pts.push(Qt.point(x, y))
                        }
                        return pts
                    }
                }
            }
        }
    }
    Rectangle { anchors.fill: parent    // soft fade at the edges
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#040405" } GradientStop { position: 0.15; color: "transparent" }
            GradientStop { position: 0.85; color: "transparent" } GradientStop { position: 1; color: "#040405" } } }
}
