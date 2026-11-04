import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

// Window headers: point at the top edge of a window and a slim header slides in with its title and
// float / fullscreen / close buttons. Never on fullscreen windows (games). Customize → Windows.
// Each window gets its own small surface: a thin strip in the gap above it (so it never blocks the
// app), which grows into the header while you point at it.
Scope {
    id: root
    readonly property var s: Settings.data
    readonly property bool on: s.windowHeaders
    readonly property int trig: s.headerTrigger || 8
    readonly property int hh: s.headerHeight || 32

    // window positions: refresh on Hyprland events, and every 1.5 s for resizes (they send no event)
    readonly property var events: ["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen",
                                   "workspacev2", "activewindowv2", "focusedmonv2", "windowtitlev2", "pin"]
    Connections {
        target: Hyprland
        enabled: root.on
        function onRawEvent(e) { if (root.events.includes(e.name)) refresh.restart() }
    }
    Timer { id: refresh; interval: 60; onTriggered: Hyprland.refreshToplevels() }
    Timer { interval: 1500; repeat: true; running: root.on; onTriggered: Hyprland.refreshToplevels() }
    Component.onCompleted: { Hyprland.refreshMonitors(); Hyprland.refreshToplevels() }

    function act(dsp, address) { Hyprland.dispatch(`hl.dsp.window.${dsp.replace("$W", "address:" + address)}`) }

    Variants {
        model: root.on ? Quickshell.screens : []

        Scope {
            id: perScreen
            required property var modelData
            readonly property var mon: Hyprland.monitorFor(modelData)
            readonly property var mi: mon && mon.lastIpcObject ? mon.lastIpcObject : null
            readonly property int wsId: mon && mon.activeWorkspace ? mon.activeWorkspace.id : -1

            // address → box (screen coordinates) for windows on the visible workspace that get a header
            readonly property var boxes: {
                const out = {}
                if (!mi) return out
                const all = Hyprland.toplevels.values.map(t => t.lastIpcObject).filter(o => o && o.address && o.at && o.size
                    && o.mapped !== false && !o.hidden && o.workspace && o.workspace.id === wsId)
                if (all.some(o => o.fullscreen > 0)) return out          // fullscreen app here: no headers at all
                const list = all.map(o => ({ address: o.address, title: o.title || o.class || "", cls: o.class || "",
                                             floating: !!o.floating, x: o.at[0] - mi.x, y: o.at[1] - mi.y, w: o.size[0], h: o.size[1] }))
                // skip a tiled window whose strip would sit on top of a floating window (it would block clicks there)
                const floats = list.filter(b => b.floating)
                for (const b of list)
                    if (b.floating || !floats.some(f => b.y - root.trig < f.y + f.h && b.y + 2 > f.y && b.x < f.x + f.w && b.x + b.w > f.x))
                        out[b.address] = b
                return out
            }
            // the model is the list of addresses (strings), so a refresh doesn't recreate the surfaces
            readonly property var addresses: Object.keys(boxes).sort()
            property string shown: ""
            onBoxesChanged: if (shown && !boxes[shown]) shown = ""

            Variants {
                model: perScreen.addresses

                PanelWindow {
                    id: strip
                    required property string modelData
                    readonly property var b: perScreen.boxes[modelData] || null
                    readonly property bool open: perScreen.shown === modelData
                    screen: perScreen.modelData
                    visible: b !== null
                    anchors { top: true; left: true }
                    margins { left: b ? b.x : 0; top: b ? Math.max(0, b.y - root.trig) : 0 }
                    implicitWidth: b ? b.w : 1
                    implicitHeight: open ? root.trig + root.hh + 2 : root.trig + 2
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "paleos-header"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                    Timer { id: hide; interval: root.s.headerDelay || 350; onTriggered: if (!area.containsMouse && perScreen.shown === strip.modelData) perScreen.shown = "" }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        onEntered: { hide.stop(); perScreen.shown = strip.modelData }
                        onExited: hide.restart()
                        onDoubleClicked: root.act(`fullscreen({ mode = "maximized", window = "$W" })`, strip.modelData)
                    }

                    Rectangle {
                        id: header
                        y: root.trig; width: parent.width; height: root.hh
                        opacity: strip.open ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        topLeftRadius: root.s.rounding; topRightRadius: root.s.rounding
                        color: Qt.rgba(0.055, 0.055, 0.055, root.s.headerOpacity || 0.94)
                        border.color: Theme.border

                        IconImage {
                            id: appIcon
                            x: 10; anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 16
                            source: strip.b ? Quickshell.iconPath((DesktopEntries.heuristicLookup(strip.b.cls) || {}).icon || strip.b.cls.toLowerCase(), "application-x-executable") : ""
                        }
                        Text {
                            anchors.left: appIcon.right; anchors.leftMargin: 8
                            anchors.right: buttons.left; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: strip.b ? strip.b.title : ""
                            elide: Text.ElideRight
                            color: Theme.fg; font.family: Theme.font; font.pixelSize: 12
                        }
                        Row {
                            id: buttons
                            anchors.right: parent.right; anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            HeaderButton { visible: !root.s.headerHideFloat; glyph: strip.b && strip.b.floating ? 0xF0570 : 0xF05B2     // tile : float
                                           onClicked: root.act(`float({ action = "toggle", window = "$W" })`, strip.modelData) }
                            HeaderButton { visible: !root.s.headerHideFullscreen; glyph: 0xF0293                     // fullscreen
                                           onClicked: { const a = strip.modelData; perScreen.shown = ""; root.act(`fullscreen({ mode = "fullscreen", window = "$W" })`, a) } }
                            HeaderButton { visible: !root.s.headerHideClose; glyph: 0xF0156; danger: true            // close
                                           onClicked: { const a = strip.modelData; perScreen.shown = ""; root.act(`close({ window = "$W" })`, a) } }
                        }
                    }
                }
            }
        }
    }

    component HeaderButton: Rectangle {
        id: hb
        property int glyph: 0
        property bool danger: false
        signal clicked()
        width: 26; height: 22; radius: 6
        color: ma.containsMouse ? (danger ? Qt.rgba(0.88, 0.42, 0.42, 0.22) : Theme.hover) : "transparent"
        Text { anchors.centerIn: parent; text: Theme.icon(hb.glyph); font.family: Theme.font; font.pixelSize: 14
               color: ma.containsMouse && hb.danger ? Theme.red : ma.containsMouse ? Theme.fg : Theme.dim }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hb.clicked() }
    }
}
