import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Screensaver (started by hypridle, or System → Screensaver): a screen overlay — not a window,
// so it never touches any app's fullscreen state. The Arch logo builds in and dissolves with a
// random effect, glyph style and light each cycle, over a faint star field with a dim clock;
// between cycles the logo leaves a soft afterglow. Any key, click or mouse movement ends it.
Scope {
    id: saver
    property bool active: false
    property real t: 0
    readonly property var cells: [[0, 18, "-"], [0, 19, "`"], [1, 17, "."], [1, 18, "o"], [1, 19, "+"], [1, 20, "`"], [2, 16, "`"], [2, 17, "o"], [2, 18, "o"], [2, 19, "o"], [2, 20, "/"], [3, 15, "`"], [3, 16, "+"], [3, 17, "o"], [3, 18, "o"], [3, 19, "o"], [3, 20, "o"], [3, 21, ":"], [4, 14, "`"], [4, 15, "+"], [4, 16, "o"], [4, 17, "o"], [4, 18, "o"], [4, 19, "o"], [4, 20, "o"], [4, 21, "o"], [4, 22, ":"], [5, 14, "-"], [5, 15, "+"], [5, 16, "o"], [5, 17, "o"], [5, 18, "o"], [5, 19, "o"], [5, 20, "o"], [5, 21, "o"], [5, 22, "+"], [5, 23, ":"], [6, 12, "`"], [6, 13, "/"], [6, 14, ":"], [6, 15, "-"], [6, 16, ":"], [6, 17, "+"], [6, 18, "+"], [6, 19, "o"], [6, 20, "o"], [6, 21, "o"], [6, 22, "o"], [6, 23, "+"], [6, 24, ":"], [7, 11, "`"], [7, 12, "/"], [7, 13, "+"], [7, 14, "+"], [7, 15, "+"], [7, 16, "+"], [7, 17, "/"], [7, 18, "+"], [7, 19, "+"], [7, 20, "+"], [7, 21, "+"], [7, 22, "+"], [7, 23, "+"], [7, 24, "+"], [7, 25, ":"], [8, 10, "`"], [8, 11, "/"], [8, 12, "+"], [8, 13, "+"], [8, 14, "+"], [8, 15, "+"], [8, 16, "+"], [8, 17, "+"], [8, 18, "+"], [8, 19, "+"], [8, 20, "+"], [8, 21, "+"], [8, 22, "+"], [8, 23, "+"], [8, 24, "+"], [8, 25, "+"], [8, 26, ":"], [9, 9, "`"], [9, 10, "/"], [9, 11, "+"], [9, 12, "+"], [9, 13, "+"], [9, 14, "o"], [9, 15, "o"], [9, 16, "o"], [9, 17, "o"], [9, 18, "o"], [9, 19, "o"], [9, 20, "o"], [9, 21, "o"], [9, 22, "o"], [9, 23, "o"], [9, 24, "o"], [9, 25, "o"], [9, 26, "o"], [9, 27, "/"], [9, 28, "`"], [10, 8, "."], [10, 9, "/"], [10, 10, "o"], [10, 11, "o"], [10, 12, "o"], [10, 13, "s"], [10, 14, "s"], [10, 15, "s"], [10, 16, "s"], [10, 17, "o"], [10, 18, "+"], [10, 19, "+"], [10, 20, "o"], [10, 21, "s"], [10, 22, "s"], [10, 23, "s"], [10, 24, "s"], [10, 25, "s"], [10, 26, "s"], [10, 27, "o"], [10, 28, "+"], [10, 29, "`"], [11, 7, "."], [11, 8, "o"], [11, 9, "o"], [11, 10, "s"], [11, 11, "s"], [11, 12, "s"], [11, 13, "s"], [11, 14, "s"], [11, 15, "o"], [11, 16, "-"], [11, 17, "`"], [11, 18, "`"], [11, 19, "`"], [11, 20, "`"], [11, 21, "/"], [11, 22, "o"], [11, 23, "s"], [11, 24, "s"], [11, 25, "s"], [11, 26, "s"], [11, 27, "s"], [11, 28, "s"], [11, 29, "+"], [11, 30, "`"], [12, 6, "-"], [12, 7, "o"], [12, 8, "s"], [12, 9, "s"], [12, 10, "s"], [12, 11, "s"], [12, 12, "s"], [12, 13, "s"], [12, 14, "o"], [12, 15, "."], [12, 22, ":"], [12, 23, "s"], [12, 24, "s"], [12, 25, "s"], [12, 26, "s"], [12, 27, "s"], [12, 28, "s"], [12, 29, "s"], [12, 30, "o"], [12, 31, "."], [13, 5, ":"], [13, 6, "o"], [13, 7, "s"], [13, 8, "s"], [13, 9, "s"], [13, 10, "s"], [13, 11, "s"], [13, 12, "s"], [13, 13, "s"], [13, 14, "/"], [13, 23, "o"], [13, 24, "s"], [13, 25, "s"], [13, 26, "s"], [13, 27, "s"], [13, 28, "o"], [13, 29, "+"], [13, 30, "+"], [13, 31, "+"], [13, 32, "."], [14, 4, "/"], [14, 5, "o"], [14, 6, "s"], [14, 7, "s"], [14, 8, "s"], [14, 9, "s"], [14, 10, "s"], [14, 11, "s"], [14, 12, "s"], [14, 13, "s"], [14, 14, "/"], [14, 23, "+"], [14, 24, "s"], [14, 25, "s"], [14, 26, "s"], [14, 27, "s"], [14, 28, "o"], [14, 29, "o"], [14, 30, "o"], [14, 31, "/"], [14, 32, "-"], [15, 2, "`"], [15, 3, "/"], [15, 4, "o"], [15, 5, "s"], [15, 6, "s"], [15, 7, "s"], [15, 8, "s"], [15, 9, "s"], [15, 10, "o"], [15, 11, "+"], [15, 12, "/"], [15, 13, ":"], [15, 14, "-"], [15, 23, "-"], [15, 24, ":"], [15, 25, "/"], [15, 26, "+"], [15, 27, "o"], [15, 28, "s"], [15, 29, "s"], [15, 30, "s"], [15, 31, "s"], [15, 32, "o"], [15, 33, "+"], [15, 34, "-"], [16, 1, "`"], [16, 2, "+"], [16, 3, "s"], [16, 4, "s"], [16, 5, "o"], [16, 6, "+"], [16, 7, ":"], [16, 8, "-"], [16, 9, "`"], [16, 27, "`"], [16, 28, "."], [16, 29, "-"], [16, 30, "/"], [16, 31, "+"], [16, 32, "o"], [16, 33, "s"], [16, 34, "o"], [16, 35, ":"], [17, 0, "`"], [17, 1, "+"], [17, 2, "+"], [17, 3, ":"], [17, 4, "."], [17, 32, "`"], [17, 33, "-"], [17, 34, "/"], [17, 35, "+"], [17, 36, "/"], [18, 0, "."], [18, 1, "`"], [18, 35, "`"]]
    readonly property int artH: 19
    readonly property int artW: 37
    readonly property real build: 3
    readonly property real hold: 5
    readonly property real fade: 3
    readonly property real rest: 2
    property var orderIn: []
    property var orderOut: []
    property int style: 0
    property int light: 0
    readonly property var styles: [null, ["░", "▒", "▓", "█"], ["·", "•", "•", "●"], ["0", "1", "0", "1"], ["⠂", "⠒", "⠖", "⠿"], ["-", "+", "#", "#"]]

    function start() { if (active) return; t = 0; newCycle(); active = true }
    function stop() { active = false }
    IpcHandler { target: "screensaver"; function start(): void { saver.start() } function stop(): void { saver.stop() } }

    function effect(k, y, x, i) {
        const n = cells.length
        switch (k) {
        case 0: return (i * 7919 % n) / n
        case 1: return y / artH
        case 2: return x / artW
        case 3: return Math.min(1, Math.hypot((x - artW / 2) / artW, (y - artH / 2) / artH) * 1.6)
        case 4: return i / n
        default: return ((x * 37 % 11) / 11) * 0.6 + y / artH * 0.4
        }
    }
    function newCycle() {
        const a = Math.floor(Math.random() * 6), b = Math.floor(Math.random() * 6)
        orderIn = cells.map((c, i) => effect(a, c[0], c[1], i))
        orderOut = cells.map((c, i) => effect(b, c[0], c[1], i))
        style = Math.random() < 0.35 ? 0 : 1 + Math.floor(Math.random() * (styles.length - 1))
        light = Math.floor(Math.random() * 3)
        t = 0
    }
    function vis(i) {
        if (!orderIn.length) return 0
        if (t < build) return t / build - orderIn[i]
        if (t < build + hold) return 1
        if (t < build + hold + fade) return orderOut[i] - (t - build - hold) / fade
        return -1
    }
    function density(c) { return ".`-".indexOf(c) >= 0 ? 0 : ":/".indexOf(c) >= 0 ? 1 : c === "+" ? 2 : 3 }
    function glyph(i) { const c = cells[i], st = styles[style]; return !st ? c[2] : style === 3 ? st[(c[0] + c[1]) % 2] : st[density(c[2])] }
    function shine(y, x) {
        if (light === 1) return Math.sin(Math.hypot(x - artW / 2, (y - artH / 2) * 2) / 3 - t * 3)
        if (light === 2) return 1 - Math.min(1, Math.abs(y - ((t * 4) % (artH + 6) - 3)) / 1.5) * 2
        return Math.sin((x + y * 1.8) / 7 - t * 2.6)
    }
    Timer {   // one 30 fps clock, only while showing
        interval: 33; repeat: true; running: saver.active
        onTriggered: { saver.t += 0.033; if (saver.t > saver.build + saver.hold + saver.fade + saver.rest) saver.newCycle() }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: saver.active
            color: "black"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "paleos-screensaver"
            WlrLayershell.keyboardFocus: saver.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: saver.stop()

                Repeater {   // faint star field, always there
                    model: 90
                    delegate: Rectangle {
                        readonly property real a: Math.random()
                        readonly property real b: Math.random()
                        x: a * win.width; y: b * win.height
                        width: a > 0.93 ? 1.6 : 1; height: width; radius: width; color: "white"
                        opacity: 0.04 + 0.16 * (0.5 + 0.5 * Math.sin(saver.t * (0.6 + b) + a * 40))
                    }
                }

                Item {   // the logo
                    id: logo
                    readonly property real ch: Math.min(win.height * 0.6 / saver.artH, 34)
                    readonly property real cw: ch * 0.55
                    width: saver.artW * cw; height: saver.artH * ch
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -win.height * 0.04
                    Repeater {
                        model: saver.cells
                        delegate: Text {
                            required property var modelData
                            required property int index
                            readonly property real d: saver.vis(index)
                            readonly property real wave: saver.shine(modelData[0], modelData[1])
                            x: modelData[1] * logo.cw; y: modelData[0] * logo.ch
                            // between cycles the logo isn't gone: a soft afterglow of dim dots stays
                            text: d > 0.06 ? saver.glyph(index) : d > 0 ? "+/:-.`o"[(index + Math.floor(saver.t * 20)) % 7] : "·"
                            color: d > 0.12 ? (wave > 0.93 ? "#ffffff" : wave > 0.6 ? "#d8d8d8" : "#a8a8a8") : d > 0.05 ? "#707070" : "#ffffff"
                            opacity: d > 0 ? 1 : 0.07
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: logo.ch * 0.8
                        }
                    }
                }

                Column {   // dim clock
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom; anchors.bottomMargin: win.height * 0.07
                    spacing: 6
                    Text { id: clock; anchors.horizontalCenter: parent.horizontalCenter; color: "#5a5a5a"
                           font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; font.weight: Font.Light
                           text: Qt.formatTime(new Date(), "HH:mm") }
                    Text { id: day; anchors.horizontalCenter: parent.horizontalCenter; color: "#3a3a3a"
                           font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.letterSpacing: 2
                           text: Qt.formatDate(new Date(), "dddd, d MMMM").toUpperCase() }
                    Timer { interval: 5000; repeat: true; running: saver.active; triggeredOnStart: true
                            onTriggered: { clock.text = Qt.formatTime(new Date(), "HH:mm"); day.text = Qt.formatDate(new Date(), "dddd, d MMMM").toUpperCase() } }
                }

                MouseArea {   // any movement (after a moment) or click ends it
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.BlankCursor
                    property real sx: -1
                    property real sy: -1
                    onPositionChanged: m => {
                        if (saver.t < 1 && sx < 0) return
                        if (sx < 0) { sx = m.x; sy = m.y; return }
                        if (Math.hypot(m.x - sx, m.y - sy) > 8) { sx = -1; saver.stop() }
                    }
                    onPressed: { sx = -1; saver.stop() }
                }
            }
        }
    }
}
