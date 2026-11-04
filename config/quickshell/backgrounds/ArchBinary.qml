import QtQuick

// Arch binary — deep black. The Arch logo written in 0s and 1s that keep flipping, a light sweep
// passing through it, over faint falling binary rain.
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
    color: "#000000"
    // Samples the real Arch logo glyph into points (x, y in 0..1, edge = on the outline).
    component LogoSampler: Canvas {
        property var points: []
        property int step: 5
        width: 260; height: 260; opacity: 0
        onAvailableChanged: if (available) requestPaint()
        onPaint: {
            const g = getContext("2d"); g.reset()
            g.fillStyle = "white"; g.textAlign = "center"; g.textBaseline = "middle"
            g.font = "230px \"JetBrainsMono Nerd Font\""
            g.fillText(String.fromCodePoint(0xF08C7), 130, 130)
            // On a scaled monitor the canvas has more real pixels than 260 x 260 (325 x 325 at 1.25), and neither
            // Screen.devicePixelRatio nor getImageData says how many. So: mark the bottom-right corner, read a
            // generous area and find the mark; k = real pixels per canvas pixel.
            g.fillRect(259, 259, 1, 1)
            const img = g.getImageData(0, 0, 1040, 1040), d = img.data, iw = img.width
            let c = Math.min(iw, img.height) - 1
            while (c > 0 && d[(c * iw + c) * 4 + 3] === 0) c--
            const k = (c + 1) / 260, s = step
            const on = (x, y) => x >= 0 && y >= 0 && x < 260 && y < 260 && d[(Math.floor(y * k) * iw + Math.floor(x * k)) * 4 + 3] > 120
            const raw = []; let x0 = 260, x1 = 0, y0 = 260, y1 = 0
            for (let y = 0; y < 260; y += s) for (let x = 0; x < 260; x += s) if (on(x, y)) {
                const edge = !on(x + s, y) || !on(x - s, y) || !on(x, y + s) || !on(x, y - s)
                raw.push([x, y, edge]); x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y)
            }
            // centre on the logo's own axis (the middle of each row), not its bounding box: a stray pixel at
            // one tip would otherwise push the whole logo sideways, off the centre of the screen and clock
            const rows = {}
            for (const p of raw) { const r = rows[p[1]] || (rows[p[1]] = [p[0], p[0]]); r[0] = Math.min(r[0], p[0]); r[1] = Math.max(r[1], p[0]) }
            const mids = Object.values(rows).map(r => (r[0] + r[1]) / 2).sort((a, b) => a - b)
            const axis = mids.length ? mids[Math.floor(mids.length / 2)] : 130
            const half = Math.max(1, ...raw.map(p => Math.abs(p[0] - axis))), h = Math.max(1, y1 - y0)
            points = raw.map(p => ({ x: (p[0] - axis + half) / (2 * half), y: (p[1] - y0) / h, edge: p[2] }))
            aspect = 2 * half / h
        }
        property real aspect: 1
    }
    LogoSampler { id: logo; step: Math.round(9 / Math.max(0.6, root.detail)) }

    readonly property real logoH: fh * 0.58
    readonly property real logoW: logoH * logo.aspect
    readonly property real cell: logoH / (260 / logo.step) * 1.05      // digit size follows the sampling grid
    function hash(i, n) { const v = Math.sin(i * 12.9898 + n * 78.233) * 43758.5453; return v - Math.floor(v) }

    Repeater {   // falling binary rain, very faint
        model: Math.round(28 * root.detail * root.more)
        delegate: Text {
            required property int index
            readonly property real x0: root.hash(index, 1)
            readonly property real v: 20 + root.hash(index, 2) * 45                 // px per second
            readonly property int n: Math.floor(root.t * 2 + index)                  // new digits a couple of times a second
            x: x0 * root.width
            y: ((root.hash(index, 3) * root.height + root.t * v) % (root.height * 1.6)) - root.height * 0.6
            text: Array.from({ length: 22 }, (_, i) => root.hash(index * 31 + i, n) > 0.5 ? "1" : "0").join("\n")
            color: "white"; opacity: 0.05 + root.hash(index, 4) * 0.06
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: Math.max(9, root.fh * 0.016); lineHeight: 1.05
        }
    }
    Item {
        id: shape
        width: root.logoW; height: root.logoH
        anchors.centerIn: parent
        Repeater {
            model: logo.points.length
            delegate: Text {
                required property int index
                readonly property var p: logo.points[index] || { x: 0, y: 0, edge: false }
                readonly property int n: Math.floor(root.t * (0.6 + root.hash(index, 5) * 1.4))   // each digit flips at its own pace
                readonly property real sweep: Math.max(0, 1 - Math.abs((p.x * 0.6 + p.y) - ((root.t * 0.22) % 2.4 - 0.4)) * 4)
                x: p.x * shape.width - width / 2; y: p.y * shape.height - height / 2
                text: root.hash(index, n) > 0.5 ? "1" : "0"
                color: "white"
                opacity: (p.edge ? 0.85 : 0.42) + sweep * 0.5
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: root.cell; font.bold: p.edge || sweep > 0.4
            }
        }
    }
}
