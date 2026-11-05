import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

// Window headers: rest the pointer in the gap above a window and a header slides in with its title and
// float / fullscreen / close buttons. Never on fullscreen windows (games). Customize → Window header.
// Each window gets its own small surface: a strip filling the gap above it (never over the bar or another
// window), which grows into the header while you use it. Moving down into the app hides it at once.
Scope {
    id: root
    readonly property var s: Settings.data
    readonly property bool on: s.windowHeaders
    readonly property int hh: s.headerHeight || 32
    readonly property int inside: 2           // the strip also covers the window's top 2 px (easy to hit)

    // Window positions refresh on compositor events. While a usable header exists, a low-rate fallback also
    // catches geometry changes that some Hyprland versions do not report.
    readonly property var events: ["openwindow", "closewindow", "movewindowv2", "resizewindowv2", "changefloatingmode", "fullscreen",
                                   "workspacev2", "activewindowv2", "focusedmonv2", "windowtitlev2", "pin", "moveworkspacev2", "activespecial", "configreloaded"]
    readonly property bool shouldPoll: {
        if (!root.on) return false
        const objects = Hyprland.toplevels.values.map(t => t.lastIpcObject).filter(o => o && o.at && o.size && o.workspace
            && o.mapped !== false && !o.hidden)
        for (let i = 0; i < Quickshell.screens.length; ++i) {
            const mon = Hyprland.monitorFor(Quickshell.screens[i])
            const mi = mon && mon.lastIpcObject ? mon.lastIpcObject : null
            if (!mi || (mi.specialWorkspace && mi.specialWorkspace.name)) continue
            const wsId = mon.activeWorkspace ? mon.activeWorkspace.id : -1
            const visible = objects.filter(o => o.workspace.id === wsId)
            if (!visible.some(o => o.fullscreen > 0) && visible.some(o => o.size[0] >= 160 && o.size[1] >= 60)) return true
        }
        return false
    }
    Connections {
        target: Hyprland
        enabled: root.on
        function onRawEvent(e) { if (root.events.includes(e.name)) refresh.restart() }
    }
    Timer { id: refresh; interval: 40; onTriggered: root.refreshAll() }
    Timer { interval: 400; repeat: true; running: root.shouldPoll; onTriggered: root.refreshAll() }
    function refreshAll() { Hyprland.refreshMonitors(); Hyprland.refreshToplevels() }   // monitors: bar size, scratchpad
    Component.onCompleted: { Hyprland.refreshMonitors(); Hyprland.refreshToplevels() }

    function act(dsp, address) { Hyprland.dispatch(`hl.dsp.${dsp.replace("$W", "address:" + address)}`) }

    Variants {
        model: root.on ? Quickshell.screens : []

        Scope {
            id: perScreen
            required property var modelData
            readonly property var mon: Hyprland.monitorFor(modelData)
            readonly property var mi: mon && mon.lastIpcObject ? mon.lastIpcObject : null
            readonly property int wsId: mon && mon.activeWorkspace ? mon.activeWorkspace.id : -1

            // address → box (screen coordinates) for windows on the visible workspace that get a header;
            // `zone` = height of the free gap above the window, where its strip goes
            readonly property var boxes: {
                const out = {}
                if (!mi || (mi.specialWorkspace && mi.specialWorkspace.name)) return out   // scratchpad open: no headers
                const all = Hyprland.toplevels.values.map(t => t.lastIpcObject).filter(o => o && o.address && o.at && o.size
                    && o.mapped !== false && !o.hidden && o.workspace && o.workspace.id === wsId)
                if (all.some(o => o.fullscreen > 0)) return out          // fullscreen app here: no headers at all
                const list = all.map(o => ({ address: o.address, title: o.title || o.class || "", cls: o.class || "",
                                             floating: !!o.floating, x: o.at[0] - mi.x, y: o.at[1] - mi.y, w: o.size[0], h: o.size[1] }))
                const top = mi.reserved ? mi.reserved[1] : 0             // the bar
                const over = (a, b) => a.x < b.x + b.w && a.x + a.w > b.x  // overlap left-right
                for (const b of list) {
                    if (b.w < 160 || b.h < 60) continue                   // small popups and dialogs
                    // the gap above: up to the bar or the nearest window above (floating ones count too)
                    let edge = top
                    for (const o of list) if (o !== b && over(o, b) && o.y < b.y && o.y + o.h > edge) edge = Math.min(b.y, o.y + o.h)
                    const zone = Math.min(24, b.y - edge)
                    // a window whose top edge is under a floating window: its strip would block clicks there
                    const covered = list.some(f => f !== b && f.floating && over(f, b) && b.y - zone < f.y + f.h && b.y + root.inside > f.y)
                    if (!covered) out[b.address] = Object.assign(b, { zone: Math.max(0, zone) })
                }
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
                    readonly property int zone: b ? b.zone : 0
                    screen: perScreen.modelData
                    visible: b !== null
                    anchors { top: true; left: true }
                    margins { left: b ? b.x : 0; top: b ? b.y - zone : 0 }
                    implicitWidth: b ? b.w : 1
                    implicitHeight: zone + (open ? root.hh : root.inside)
                    color: "transparent"
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "paleos-header"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                    function show() { hide.stop(); perScreen.shown = strip.modelData }
                    // rest the pointer for a moment to open it, so moving past (e.g. up to browser tabs) doesn't
                    Timer { id: dwell; interval: 150; onTriggered: if (area.containsMouse) strip.show() }
                    Timer { id: hide; interval: root.s.headerDelay || 350; onTriggered: if (!area.containsMouse && perScreen.shown === strip.modelData) perScreen.shown = "" }
                    // left the open header: below it = down into the app, so hide at once (the header never sits
                    // on what you click next); anywhere else it stays a moment, in case you slipped off
                    Process {
                        id: where
                        command: ["hyprctl", "cursorpos", "-j"]
                        stdout: StdioCollector { onStreamFinished: {
                            let y = -1; try { y = JSON.parse(this.text).y - (perScreen.mi ? perScreen.mi.y : 0) } catch (e) {}
                            if (strip.b && y >= strip.b.y + root.hh - 2) { if (perScreen.shown === strip.modelData) perScreen.shown = "" }
                            else hide.restart()
                        } }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onEntered: strip.open ? hide.stop() : dwell.restart()
                        onExited: { dwell.stop(); if (strip.open) where.running = true }
                        onPressed: e => {
                            if (!strip.open) { strip.show(); return }
                            if (e.button === Qt.MiddleButton) root.act(`window.close({ window = "$W" })`, strip.modelData)
                            else root.act(`focus({ window = "$W" })`, strip.modelData)
                        }
                        onDoubleClicked: root.act(`window.fullscreen({ mode = "maximized", window = "$W" })`, strip.modelData)
                    }

                    Rectangle {
                        id: header
                        y: strip.zone; width: parent.width; height: root.hh
                        opacity: strip.open ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        topLeftRadius: root.s.rounding; topRightRadius: root.s.rounding
                        color: Qt.rgba(0.055, 0.055, 0.055, root.s.headerOpacity || 0.94)
                        border.color: Theme.border

                        IconImage {
                            id: appIcon
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            implicitSize: Math.round(root.hh * 0.5)
                            source: strip.b ? Quickshell.iconPath((DesktopEntries.heuristicLookup(strip.b.cls) || {}).icon || strip.b.cls.toLowerCase(), "application-x-executable") : ""
                        }
                        Text {
                            anchors.left: appIcon.right; anchors.leftMargin: 8
                            anchors.right: buttons.left; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: strip.b ? strip.b.title : ""
                            elide: Text.ElideRight
                            color: Theme.fg; font.family: Theme.font; font.pixelSize: 13
                        }
                        Row {
                            id: buttons
                            anchors.right: parent.right; anchors.rightMargin: 4
                            height: parent.height
                            HeaderButton { visible: !root.s.headerHideFloat; glyph: strip.b && strip.b.floating ? 0xF0570 : 0xF05B2     // tile : float
                                           onClicked: root.act(`window.float({ action = "toggle", window = "$W" })`, strip.modelData) }
                            HeaderButton { visible: !root.s.headerHideFullscreen; glyph: 0xF0293                     // fullscreen
                                           onClicked: { const a = strip.modelData; perScreen.shown = ""; root.act(`window.fullscreen({ mode = "fullscreen", window = "$W" })`, a) } }
                            HeaderButton { visible: !root.s.headerHideClose; glyph: 0xF0156; danger: true            // close
                                           onClicked: { const a = strip.modelData; perScreen.shown = ""; root.act(`window.close({ window = "$W" })`, a) } }
                        }
                    }
                }
            }
        }
    }

    // buttons fill the header's height, so they're easy to hit
    component HeaderButton: Item {
        id: hb
        property int glyph: 0
        property bool danger: false
        signal clicked()
        width: Math.round(root.hh * 1.15); height: parent.height
        Rectangle {
            anchors.centerIn: parent; width: parent.width - 4; height: parent.height - 8; radius: 6
            color: ma.containsMouse ? (hb.danger ? Qt.rgba(0.88, 0.42, 0.42, 0.22) : Theme.hover) : "transparent"
        }
        Text { anchors.centerIn: parent; text: Theme.icon(hb.glyph); font.family: Theme.font; font.pixelSize: 15
               color: ma.containsMouse && hb.danger ? Theme.red : ma.containsMouse ? Theme.fg : Theme.dim }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hb.clicked() }
    }
}
