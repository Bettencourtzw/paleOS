import QtQuick
import "arch.js" as Arch

// Arch particles: scattered points drift together into the Arch logo, hold with a shimmer, then
// scatter to new places — in a cycle. One 30 fps clock; stops when not running.
Rectangle {
    id: root
    property bool running: true
    property real t: 6
    color: "#040405"
    Timer { interval: 33; repeat: true; running: root.running; onTriggered: root.t += 0.033 }

    readonly property var pts: Arch.points()
    readonly property real cycle: 14                       // gather 4s · hold 5s · scatter 4s · rest 1s
    readonly property int n: Math.floor(t / cycle)          // which cycle we're in
    readonly property real ph: t % cycle
    readonly property real logoH: height * 0.5
    readonly property real logoW: logoH * Arch.aspect
    readonly property real ox: (width - logoW) / 2
    readonly property real oy: (height - logoH) / 2 - height * 0.03
    function ease(p) { p = Math.max(0, Math.min(1, p)); return p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2 }
    // 0 = scattered, 1 = in the logo
    readonly property real k: ph < 4 ? ease(ph / 4) : ph < 9 ? 1 : ph < 13 ? 1 - ease((ph - 9) / 4) : 0

    Repeater {
        model: root.pts.length
        delegate: Rectangle {
            required property int index
            readonly property var p: root.pts[index]
            readonly property real fromX: Arch.rnd(index, root.n) * root.width       // where it comes from this cycle
            readonly property real fromY: Arch.rnd(index + 999, root.n) * root.height
            readonly property real toX: Arch.rnd(index, root.n + 1) * root.width     // where it scatters to
            readonly property real toY: Arch.rnd(index + 999, root.n + 1) * root.height
            readonly property real lx: root.ox + p.x * root.logoW
            readonly property real ly: root.oy + p.y * root.logoH
            readonly property bool leaving: root.ph >= 9
            width: 2 + p.d * 2.5; height: width; radius: width
            color: "#ffffff"
            x: (leaving ? toX : fromX) * (1 - root.k) + lx * root.k
            y: (leaving ? toY : fromY) * (1 - root.k) + ly * root.k
            opacity: (0.25 + 0.55 * root.k) * (0.7 + 0.3 * Math.sin(root.t * 2 + index))
        }
    }
}
