import QtQuick
import QtQuick.Shapes

// Waves: thin lines drifting like a slow topographic map. One 30 fps clock; stops when not running.
Rectangle {
    id: root
    property bool running: true
    property real t: 20                 // starts a little way in, so the first frame isn't empty
    color: "#050506"
    Timer { interval: 33; repeat: true; running: root.running; onTriggered: root.t += 0.033 }

    Repeater {
        model: 14
        delegate: Shape {
            id: line
            required property int index
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real baseY: root.height * (0.18 + index * 0.05)
            readonly property real amp: 18 + index * 2.5
            ShapePath {
                strokeColor: Qt.rgba(1, 1, 1, 0.05 + 0.04 * Math.sin(index * 0.9))
                strokeWidth: 1
                fillColor: "transparent"
                PathPolyline {
                    path: {
                        const pts = [], n = 48, w = root.width
                        for (let i = 0; i <= n; i++) {
                            const x = w * i / n
                            const y = line.baseY
                                + Math.sin(i / n * 6.28 * 1.5 + root.t * 0.35 + line.index * 0.6) * line.amp
                                + Math.sin(i / n * 6.28 * 0.5 - root.t * 0.2 + line.index) * line.amp * 0.6
                            pts.push(Qt.point(x, y))
                        }
                        return pts
                    }
                }
            }
        }
    }
}
