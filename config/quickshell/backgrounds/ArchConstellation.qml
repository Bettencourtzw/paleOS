import QtQuick

// Arch constellation — the Arch logo traced in stars and joined by faint lines, hanging in a
// night sky with drifting clouds. Stars twinkle; a slow light sweep passes through.
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
    gradient: Gradient { GradientStop { position: 0; color: "#070912" } GradientStop { position: 0.7; color: "#030407" } GradientStop { position: 1; color: "#010102" } }
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
    LogoSampler { id: logo; step: 6 }
    // the constellation = outline points, thinned out
    readonly property var stars: logo.points.filter(p => p.edge)
    readonly property real logoH: fh * 0.6
    readonly property real logoW: logoH * logo.aspect

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
                for (let i = 0; i < 60 * Math.min(4, W / root.fw); i++) {
                    const x = Math.random() * W, y = (cl.bandTop + Math.random() * cl.band) * height, r = root.fw * (0.05 + Math.random() * 0.12)
                    for (const dx of [0, W]) {
                        const gr = g.createRadialGradient(x + dx, y, 0, x + dx, y, r)
                        gr.addColorStop(0, Qt.rgba(0.7, 0.76, 0.9, cl.alpha)); gr.addColorStop(1, Qt.rgba(0.7, 0.76, 0.9, 0))
                        g.fillStyle = gr; g.beginPath(); g.ellipse(x + dx - r * 1.6, y - r * 0.5, r * 3.2, r); g.fill()
                    }
                }
            }
        }
    }
    Repeater {   // far stars
        model: Math.round(140 * root.detail * root.more)
        delegate: Rectangle {
            readonly property real a: Math.random()
            readonly property real b: Math.random()
            x: a * root.width; y: b * root.height
            width: a > 0.94 ? 1.6 : 1; height: width; radius: width; color: "white"
            opacity: 0.05 + 0.22 * (0.5 + 0.5 * Math.sin(root.t * (0.5 + b) + a * 6.28))
        }
    }
    Clouds { alpha: 0.016; px: 6; bandTop: 0.0; band: 0.45 }
    Clouds { alpha: 0.022; px: 12; bandTop: 0.55; band: 0.45 }

    Item {
        id: shape
        width: root.logoW; height: root.logoH
        x: (root.width - width) / 2 + Math.sin(root.t * 0.04) * 24
        y: (root.height - height) / 2 + Math.cos(root.t * 0.03) * 14
        Canvas {   // lines between nearby stars, drawn once
            anchors.fill: parent; renderStrategy: Canvas.Cooperative
            opacity: 0.55 + 0.45 * Math.sin(root.t * 0.2)
            onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
            readonly property int count: root.stars.length   // repaint once the logo has been sampled
            onCountChanged: requestPaint()
            onPaint: {
                const g = getContext("2d"); g.reset(); const s = root.stars; if (width <= 0 || !s.length) return
                g.strokeStyle = Qt.rgba(1, 1, 1, 0.22); g.lineWidth = 1
                for (let i = 0; i < s.length; i++) {       // each star links to its two nearest neighbours
                    const near = s.map((q, j) => [j, Math.hypot((q.x - s[i].x) * root.logoW, (q.y - s[i].y) * root.logoH)])
                                  .filter(e => e[0] !== i).sort((a, b) => a[1] - b[1]).slice(0, 2)
                    for (const [j, dist] of near) if (dist < root.logoH * 0.09) {
                        g.beginPath(); g.moveTo(s[i].x * width, s[i].y * height); g.lineTo(s[j].x * width, s[j].y * height); g.stroke()
                    }
                }
            }
        }
        Repeater {
            model: root.stars.length
            delegate: Item {
                required property int index
                readonly property var p: root.stars[index] || { x: 0, y: 0 }
                readonly property real sweep: Math.max(0, 1 - Math.abs((p.x + p.y) - ((root.t * 0.16) % 3.2 - 0.6)) * 3)
                x: p.x * shape.width; y: p.y * shape.height
                Rectangle { x: -width / 2; y: -height / 2; width: 2.8 + sweep * 2.4; height: width; radius: width; color: "white"
                            opacity: 0.6 + 0.3 * Math.sin(root.t * (0.8 + (index % 5) * 0.2) + index) + sweep * 0.25 }
            }
        }
    }
}
