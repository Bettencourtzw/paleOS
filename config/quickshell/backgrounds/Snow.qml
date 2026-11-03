import QtQuick

// Snow: gentle flakes falling at three depths with a little sway. One 30 fps clock; stops when not running.
Rectangle {
    id: root
    property bool running: true
    property real t: 20                 // starts a little way in, so the first frame isn't empty
    gradient: Gradient { GradientStop { position: 0; color: "#07080b" } GradientStop { position: 1; color: "#0d0e12" } }
    Timer { interval: 33; repeat: true; running: root.running; onTriggered: root.t += 0.033 }

    Repeater {
        model: 140
        delegate: Rectangle {
            readonly property real depth: Math.random()            // 0 far .. 1 near
            readonly property real x0: Math.random()
            readonly property real y0: Math.random()
            readonly property real speed: 18 + depth * 55           // px per second
            readonly property real fall: (y0 * (root.height + 20) + root.t * speed) % (root.height + 20) - 10
            width: 1.5 + depth * 3; height: width; radius: width
            color: "#ffffff"
            opacity: 0.12 + depth * 0.35
            x: x0 * root.width + Math.sin(root.t * (0.4 + depth) + x0 * 20) * (6 + depth * 14)
            y: fall
        }
    }
}
