// SDDM login: animated Arch logo (random clean effect each cycle) + password beneath.
import QtQuick 2.15

Rectangle {
    id: root
    width: 1920; height: 1080
    readonly property string font: config.font || "monospace"
    readonly property var cells: [[0, 18, "-"], [0, 19, "`"], [1, 17, "."], [1, 18, "o"], [1, 19, "+"], [1, 20, "`"], [2, 16, "`"], [2, 17, "o"], [2, 18, "o"], [2, 19, "o"], [2, 20, "/"], [3, 15, "`"], [3, 16, "+"], [3, 17, "o"], [3, 18, "o"], [3, 19, "o"], [3, 20, "o"], [3, 21, ":"], [4, 14, "`"], [4, 15, "+"], [4, 16, "o"], [4, 17, "o"], [4, 18, "o"], [4, 19, "o"], [4, 20, "o"], [4, 21, "o"], [4, 22, ":"], [5, 14, "-"], [5, 15, "+"], [5, 16, "o"], [5, 17, "o"], [5, 18, "o"], [5, 19, "o"], [5, 20, "o"], [5, 21, "o"], [5, 22, "+"], [5, 23, ":"], [6, 12, "`"], [6, 13, "/"], [6, 14, ":"], [6, 15, "-"], [6, 16, ":"], [6, 17, "+"], [6, 18, "+"], [6, 19, "o"], [6, 20, "o"], [6, 21, "o"], [6, 22, "o"], [6, 23, "+"], [6, 24, ":"], [7, 11, "`"], [7, 12, "/"], [7, 13, "+"], [7, 14, "+"], [7, 15, "+"], [7, 16, "+"], [7, 17, "/"], [7, 18, "+"], [7, 19, "+"], [7, 20, "+"], [7, 21, "+"], [7, 22, "+"], [7, 23, "+"], [7, 24, "+"], [7, 25, ":"], [8, 10, "`"], [8, 11, "/"], [8, 12, "+"], [8, 13, "+"], [8, 14, "+"], [8, 15, "+"], [8, 16, "+"], [8, 17, "+"], [8, 18, "+"], [8, 19, "+"], [8, 20, "+"], [8, 21, "+"], [8, 22, "+"], [8, 23, "+"], [8, 24, "+"], [8, 25, "+"], [8, 26, ":"], [9, 9, "`"], [9, 10, "/"], [9, 11, "+"], [9, 12, "+"], [9, 13, "+"], [9, 14, "o"], [9, 15, "o"], [9, 16, "o"], [9, 17, "o"], [9, 18, "o"], [9, 19, "o"], [9, 20, "o"], [9, 21, "o"], [9, 22, "o"], [9, 23, "o"], [9, 24, "o"], [9, 25, "o"], [9, 26, "o"], [9, 27, "/"], [9, 28, "`"], [10, 8, "."], [10, 9, "/"], [10, 10, "o"], [10, 11, "o"], [10, 12, "o"], [10, 13, "s"], [10, 14, "s"], [10, 15, "s"], [10, 16, "s"], [10, 17, "o"], [10, 18, "+"], [10, 19, "+"], [10, 20, "o"], [10, 21, "s"], [10, 22, "s"], [10, 23, "s"], [10, 24, "s"], [10, 25, "s"], [10, 26, "s"], [10, 27, "o"], [10, 28, "+"], [10, 29, "`"], [11, 7, "."], [11, 8, "o"], [11, 9, "o"], [11, 10, "s"], [11, 11, "s"], [11, 12, "s"], [11, 13, "s"], [11, 14, "s"], [11, 15, "o"], [11, 16, "-"], [11, 17, "`"], [11, 18, "`"], [11, 19, "`"], [11, 20, "`"], [11, 21, "/"], [11, 22, "o"], [11, 23, "s"], [11, 24, "s"], [11, 25, "s"], [11, 26, "s"], [11, 27, "s"], [11, 28, "s"], [11, 29, "+"], [11, 30, "`"], [12, 6, "-"], [12, 7, "o"], [12, 8, "s"], [12, 9, "s"], [12, 10, "s"], [12, 11, "s"], [12, 12, "s"], [12, 13, "s"], [12, 14, "o"], [12, 15, "."], [12, 22, ":"], [12, 23, "s"], [12, 24, "s"], [12, 25, "s"], [12, 26, "s"], [12, 27, "s"], [12, 28, "s"], [12, 29, "s"], [12, 30, "o"], [12, 31, "."], [13, 5, ":"], [13, 6, "o"], [13, 7, "s"], [13, 8, "s"], [13, 9, "s"], [13, 10, "s"], [13, 11, "s"], [13, 12, "s"], [13, 13, "s"], [13, 14, "/"], [13, 23, "o"], [13, 24, "s"], [13, 25, "s"], [13, 26, "s"], [13, 27, "s"], [13, 28, "o"], [13, 29, "+"], [13, 30, "+"], [13, 31, "+"], [13, 32, "."], [14, 4, "/"], [14, 5, "o"], [14, 6, "s"], [14, 7, "s"], [14, 8, "s"], [14, 9, "s"], [14, 10, "s"], [14, 11, "s"], [14, 12, "s"], [14, 13, "s"], [14, 14, "/"], [14, 23, "+"], [14, 24, "s"], [14, 25, "s"], [14, 26, "s"], [14, 27, "s"], [14, 28, "o"], [14, 29, "o"], [14, 30, "o"], [14, 31, "/"], [14, 32, "-"], [15, 2, "`"], [15, 3, "/"], [15, 4, "o"], [15, 5, "s"], [15, 6, "s"], [15, 7, "s"], [15, 8, "s"], [15, 9, "s"], [15, 10, "o"], [15, 11, "+"], [15, 12, "/"], [15, 13, ":"], [15, 14, "-"], [15, 23, "-"], [15, 24, ":"], [15, 25, "/"], [15, 26, "+"], [15, 27, "o"], [15, 28, "s"], [15, 29, "s"], [15, 30, "s"], [15, 31, "s"], [15, 32, "o"], [15, 33, "+"], [15, 34, "-"], [16, 1, "`"], [16, 2, "+"], [16, 3, "s"], [16, 4, "s"], [16, 5, "o"], [16, 6, "+"], [16, 7, ":"], [16, 8, "-"], [16, 9, "`"], [16, 27, "`"], [16, 28, "."], [16, 29, "-"], [16, 30, "/"], [16, 31, "+"], [16, 32, "o"], [16, 33, "s"], [16, 34, "o"], [16, 35, ":"], [17, 0, "`"], [17, 1, "+"], [17, 2, "+"], [17, 3, ":"], [17, 4, "."], [17, 32, "`"], [17, 33, "-"], [17, 34, "/"], [17, 35, "+"], [17, 36, "/"], [18, 0, "."], [18, 1, "`"], [18, 35, "`"]]
    readonly property int artH: 19
    readonly property int artW: 37
    // last user, or the first account on a fresh install; click the name to switch accounts
    property int userIndex: 0
    function userAt(i) { return userModel.data(userModel.index(i, 0), Qt.UserRole + 1) || "" }
    property string user: userModel.lastUser !== "" ? userModel.lastUser : userAt(0)
    property int session: sessionModel.lastIndex
    property bool failed: false

    // ---- logo animation -------------------------------------------------
    property real t: 0
    property var orderIn: []
    property var orderOut: []
    readonly property real build: 3
    readonly property real hold: 5
    readonly property real fade: 3
    readonly property real rest: 1
    function effect(k, y, x, i) {
        const n = cells.length
        switch (k) {
        case 0: return (i * 7919 % n) / n                                   // dissolve
        case 1: return y / artH                                             // wipe down
        case 2: return x / artW                                             // wipe side
        case 3: return Math.min(1, Math.hypot((x - artW / 2) / artW, (y - artH / 2) / artH) * 1.6)  // center out
        case 4: return i / n                                                // typewriter
        default: return ((x * 37 % 11) / 11) * 0.6 + y / artH * 0.4        // rain
        }
    }
    // character styles: each maps the logo's shading (0 light .. 3 dense) to glyphs
    readonly property var styles: [
        null,                              // original letters
        ["░", "▒", "▓", "█"],
        ["·", "•", "•", "●"],
        ["0", "1", "0", "1"],
        ["⠂", "⠒", "⠖", "⠿"],
        ["-", "+", "#", "#"]
    ]
    property int style: 0
    property int light: 0                  // 0 diagonal sweep, 1 center pulse, 2 scanline
    function density(c) { return ".`-".indexOf(c) >= 0 ? 0 : ":/".indexOf(c) >= 0 ? 1 : c === "+" ? 2 : 3 }
    function glyph(i) {
        const c = cells[i]; const st = styles[style]
        if (!st) return c[2]
        return style === 3 ? st[(c[0] + c[1]) % 2] : st[density(c[2])]
    }
    function shine(y, x) {
        if (light === 1) return Math.sin(Math.hypot(x - artW / 2, (y - artH / 2) * 2) / 3 - t * 3)
        if (light === 2) return 1 - Math.min(1, Math.abs(y - ((t * 4) % (artH + 6) - 3)) / 1.5) * 2
        return Math.sin((x + y * 1.8) / 7 - t * 2.6)
    }
    function newCycle() {
        style = Math.random() < 0.35 ? 0 : 1 + Math.floor(Math.random() * (styles.length - 1))
        light = Math.floor(Math.random() * 3)
        const a = Math.floor(Math.random() * 6), b = Math.floor(Math.random() * 6)
        orderIn = cells.map((c, i) => effect(a, c[0], c[1], i))
        orderOut = cells.map((c, i) => effect(b, c[0], c[1], i))
        t = 0
    }
    Component.onCompleted: { newCycle(); pass.forceActiveFocus() }
    Timer {
        interval: 33; running: true; repeat: true
        onTriggered: { root.t += 0.033; if (root.t > root.build + root.hold + root.fade + root.rest) root.newCycle() }
    }
    function vis(i) {
        if (!orderIn.length) return 0
        if (t < build) return t / build - orderIn[i]
        if (t < build + hold) return 1
        if (t < build + hold + fade) return orderOut[i] - (t - build - hold) / fade
        return -1
    }


    // ---- animated background: night sky — drifting clouds + faint stars ----
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#06070a" }
        GradientStop { position: 1.0; color: "#020203" }
    }
    Repeater {   // stars
        model: 110
        delegate: Rectangle {
            required property int index
            readonly property real r: Math.random()
            readonly property real q: Math.random()
            x: q * root.width; y: r * root.height * 0.75
            width: r > 0.9 ? 2 : 1; height: width; radius: width
            color: "#ffffff"
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.05; to: 0.35 + 0.3 * q; duration: 2500 + r * 4000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.05; duration: 2500 + q * 4000; easing.type: Easing.InOutSine }
            }
        }
    }
    component CloudLayer: Item {
        id: layer
        property int seed: 1
        property real alpha: 0.05
        property int seconds: 240
        property real bandTop: 0.0       // vertical band (fraction of screen)
        property real band: 1.0
        width: root.width * 2; height: root.height
        Canvas {
            anchors.fill: parent
            onPaint: {
                const g = getContext("2d"); let s = layer.seed
                const rnd = () => { s = (s * 16807) % 2147483647; return s / 2147483647 }
                const W = root.width
                for (let i = 0; i < 90; i++) {
                    const x = rnd() * W, y = (layer.bandTop + rnd() * layer.band) * height
                    const rad = 80 + rnd() * 260
                    for (const dx of [0, W]) {      // drawn twice so the loop is seamless
                        const gr = g.createRadialGradient(x + dx, y, 0, x + dx, y, rad)
                        gr.addColorStop(0, Qt.rgba(0.75, 0.80, 0.92, layer.alpha))
                        gr.addColorStop(1, Qt.rgba(0.75, 0.80, 0.92, 0))
                        g.fillStyle = gr
                        g.beginPath(); g.ellipse(x + dx - rad * 1.6, y - rad * 0.6, rad * 3.2, rad * 1.2); g.fill()
                    }
                }
            }
        }
        NumberAnimation on x { from: 0; to: -root.width; duration: layer.seconds * 1000; loops: Animation.Infinite }
    }
    CloudLayer { seed: 1 + Math.floor(Math.random() * 1e6); alpha: 0.010; seconds: 480; bandTop: 0.0;  band: 0.5 }   // far, slowest
    CloudLayer { seed: 1 + Math.floor(Math.random() * 1e6); alpha: 0.015; seconds: 300; bandTop: 0.3;  band: 0.5 }   // middle
    CloudLayer { seed: 1 + Math.floor(Math.random() * 1e6); alpha: 0.020; seconds: 170; bandTop: 0.6;  band: 0.45 }  // near, fastest

    // fog along the bottom, slowly breathing
    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: parent.height * 0.35
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#0a0b0f" }
        }
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 0.5; to: 0.9; duration: 7000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.9; to: 0.5; duration: 7000; easing.type: Easing.InOutSine }
        }
    }

    // shooting stars at random moments, random angle and place
    Item {
        id: meteor
        property real ang: 0
        width: 140; height: 1.5
        opacity: 0
        rotation: ang
        Rectangle {
            anchors.fill: parent; radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "#ddffffff" }
            }
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
            interval: 6000; running: true; repeat: true
            onTriggered: {
                interval = 5000 + Math.random() * 11000
                meteor.ang = 20 + Math.random() * 25
                const sx = Math.random() * root.width * 0.8, sy = Math.random() * root.height * 0.4
                const dist = 300 + Math.random() * 350, a = meteor.ang * Math.PI / 180
                fx.from = sx; fx.to = sx + Math.cos(a) * dist
                fy.from = sy; fy.to = sy + Math.sin(a) * dist
                fly.restart()
            }
        }
    }

    Item {
        id: logo
        readonly property real cw: 16
        readonly property real ch: 30
        width: root.artW * cw; height: root.artH * ch
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -50
        z: 2
        Repeater {
            model: root.cells
            delegate: Text {
                required property var modelData
                required property int index
                readonly property real d: root.vis(index)
                x: modelData[1] * logo.cw; y: modelData[0] * logo.ch
                text: d > 0.06 ? root.glyph(index) : "+/:-.`o"[(index + Math.floor(root.t * 20)) % 7]
                visible: d > 0
                readonly property real wave: root.shine(modelData[0], modelData[1])
                color: d > 0.12 ? (wave > 0.93 ? "#ffffff" : wave > 0.6 ? "#d8d8d8" : "#a8a8a8") : d > 0.05 ? "#707070" : "#3a3a3a"
                font.family: root.font; font.pixelSize: 25
            }
        }
    }

    // ---- password field (bottom) ----
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 120
        width: 320; height: 46; radius: 23
        color: "#330e0e0e"
        border.width: 1; border.color: root.failed ? "#e06c6c" : "#33ffffff"
        property real shake: 0
        transform: Translate { x: pill.shake }
        SequentialAnimation on shake {
            id: shakeAnim; running: false
            NumberAnimation { to: -8; duration: 35 }
            NumberAnimation { to: 8; duration: 50 }
            NumberAnimation { to: 0; duration: 55 }
        }
        TextInput {
            id: pass
            anchors.fill: parent; anchors.leftMargin: 22; anchors.rightMargin: 22
            verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignHCenter
            echoMode: TextInput.Password; passwordCharacter: "•"
            color: "#e6e6e6"; font.family: root.font; font.pixelSize: 16
            clip: true; focus: true
            onTextChanged: root.failed = false
            onAccepted: sddm.login(root.user, text, root.session)
        }
        MouseArea {   // switch account (only when there is more than one)
            anchors.fill: parent
            enabled: userModel.count > 1 && pass.text.length === 0
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.IBeamCursor
            onClicked: { root.userIndex = (root.userIndex + 1) % userModel.count; root.user = root.userAt(root.userIndex); pass.forceActiveFocus() }
        }
        Text {
            anchors.centerIn: parent
            visible: pass.text.length === 0
            text: root.failed ? "Wrong password" : root.user + (userModel.count > 1 ? "  " + String.fromCodePoint(0xF0140) : "")
            color: root.failed ? "#e06c6c" : "#7a7a7a"
            font.family: root.font; font.pixelSize: 14
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() { root.failed = true; pass.text = ""; shakeAnim.start(); pass.forceActiveFocus() }
    }

    // bottom-right: power button + popup menu
    property bool powerOpen: false
    MouseArea {   // click anywhere else closes the popup
        anchors.fill: parent; visible: root.powerOpen; z: 9
        onClicked: root.powerOpen = false
    }
    Rectangle {
        id: powerMenu
        z: 10
        visible: root.powerOpen
        opacity: root.powerOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        anchors.right: powerBtn.right; anchors.bottom: powerBtn.top; anchors.bottomMargin: 10
        width: 190; height: col.implicitHeight + 12
        radius: 12; color: "#0e0e0e"; border.width: 1; border.color: "#2a2a2a"
        Column {
            id: col
            x: 6; y: 6; width: parent.width - 12; spacing: 2
            Repeater {
                model: [
                    { t: "Suspend",   g: "\u{F04B2}", ok: sddm.canSuspend, a: function() { sddm.suspend() } },
                    { t: "Restart",   g: "\u{F0709}", ok: true,            a: function() { sddm.reboot() } },
                    { t: "Shut down", g: "\u{F0425}", ok: true,            a: function() { sddm.powerOff() } }
                ]
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.ok
                    width: parent.width; height: visible ? 36 : 0; radius: 8
                    color: ma.containsMouse ? "#1f1f1f" : "transparent"
                    Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.g; color: "#bdbdbd"; font.family: root.font; font.pixelSize: 15 }
                    Text { x: 40; anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: "#e6e6e6"; font.family: root.font; font.pixelSize: 13 }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.a() }
                }
            }
        }
    }
    Rectangle {
        id: powerBtn
        z: 10
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 28
        width: 40; height: 40; radius: 20
        color: pb.containsMouse || root.powerOpen ? "#1f1f1f" : "transparent"
        border.width: 1; border.color: root.powerOpen ? "#3a3a3a" : "#262626"
        Text { anchors.centerIn: parent; text: String.fromCodePoint(0xF0425); color: pb.containsMouse || root.powerOpen ? "#e6e6e6" : "#7a7a7a"; font.family: root.font; font.pixelSize: 25 }
        MouseArea { id: pb; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.powerOpen = !root.powerOpen }
    }
}
