import QtQuick

// Arch particles — deep black. Particles spiral in to form the Arch logo, shimmer as a wave runs
// through them, then spiral back out. Repeats.
Rectangle {
    id: root
    property bool running: true
    property int fps: 30
    property real speed: 1
    property real detail: 1
    property real t: 20
    Timer { interval: Math.round(1000 / Math.max(5, root.fps)); repeat: true; running: root.running; onTriggered: root.t += root.speed * interval / 1000 }
    // Sizes follow the largest 16:9 area that fits (fh = its height), so the logo stays whole on ultrawide or portrait screens
    readonly property real fh: Math.min(height, width * 9 / 16)
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
            const w = Math.max(1, x1 - x0), h = Math.max(1, y1 - y0)
            points = raw.map(p => ({ x: (p[0] - x0) / w, y: (p[1] - y0) / h, edge: p[2] }))
            aspect = w / h
        }
        property real aspect: 1
    }
    LogoSampler { id: logo; step: Math.round(7 / Math.max(0.5, root.detail)) }

    readonly property var pts: logo.points
    readonly property real cycle: 16                        // in 5s · hold 6s · out 4s · rest 1s
    readonly property real ph: t % cycle
    readonly property real logoH: fh * 0.52
    readonly property real logoW: logoH * logo.aspect
    readonly property real cx: width / 2
    readonly property real cy: height / 2 - height * 0.02
    function ease(p) { p = Math.max(0, Math.min(1, p)); return p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2 }
    readonly property real k: ph < 5 ? ease(ph / 5) : ph < 11 ? 1 : ph < 15 ? 1 - ease((ph - 11) / 4) : 0
    readonly property real far: Math.max(width, height) * 0.75

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
    Glow {   // soft light behind the logo while it's formed
        anchors.centerIn: parent; width: root.fh * 1.1; height: width; strength: 0.05; opacity: root.k
    }
    Repeater {
        model: root.pts.length
        delegate: Rectangle {
            required property int index
            readonly property var p: root.pts[index] || { x: 0, y: 0, edge: false }
            readonly property real seed: Math.sin(index * 12.9898) * 43758.5453 % 1
            // target in the logo (polar, around the centre)
            readonly property real jx: (Math.sin(index * 78.233) * 43758.5453 % 1) * 0.012
            readonly property real jy: (Math.sin(index * 39.425) * 24634.6345 % 1) * 0.012
            readonly property real tx: (p.x + jx - 0.5) * root.logoW
            readonly property real ty: (p.y + jy - 0.5) * root.logoH
            readonly property real tr: Math.hypot(tx, ty)
            readonly property real ta: Math.atan2(ty, tx)
            // spiral: radius shrinks in, angle unwinds
            readonly property real r: tr * root.k + root.far * (0.6 + Math.abs(seed) * 0.4) * (1 - root.k)
            readonly property real a: ta + (1 - root.k) * (2.4 + seed)
            readonly property real wave: root.k === 1 ? Math.sin((p.x + p.y) * 6 - root.t * 2.2) : 0
            width: p.edge ? 2.6 : 2; height: width; radius: width
            color: "white"
            x: root.cx + Math.cos(a) * r - width / 2
            y: root.cy + Math.sin(a) * r - height / 2 - wave * 1.5
            opacity: (0.15 + 0.7 * root.k) * (p.edge ? 1 : 0.55) * (0.8 + 0.2 * wave)
        }
    }
}
