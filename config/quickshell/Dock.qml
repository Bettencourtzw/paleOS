import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Dock at the bottom: an apps button, pinned apps, then open apps.
//   click: open / switch to the app      right-click: menu (open, new window, pin/unpin, close)
//   drag: reorder pinned apps (drop an open app among them to pin it)
// Looks and behaviour are set in Customize → Dock.
Scope {
    id: dock
    readonly property var s: Settings.data

    // ---- apps ---------------------------------------------------------------------------------
    function lookup(id) { return DesktopEntries.byId(id) || DesktopEntries.byId(id.replace(/\.desktop$/, "")) || DesktopEntries.heuristicLookup(id.replace(/\.desktop$/, "")) }
    // re-evaluated once the app list has loaded (it loads in the background)
    readonly property var pinned: { DesktopEntries.applications.values.length; return s.dockPinned.map(id => dock.lookup(id)).filter(e => e) }
    readonly property var windows: Hyprland.toplevels.values.filter(t => t.lastIpcObject && t.lastIpcObject.class)
    function entryFor(cls) { return DesktopEntries.heuristicLookup(cls) }
    function windowsOf(e) {
        const ids = [e.id.toLowerCase(), (e.startupClass || "").toLowerCase()]
        return windows.filter(t => { const c = (t.lastIpcObject.class || "").toLowerCase(); return ids.includes(c) || (entryFor(t.lastIpcObject.class) || {}).id === e.id })
    }
    readonly property var running: {
        const seen = new Set(pinned.map(e => e.id)), out = []
        for (const t of windows) { const e = entryFor(t.lastIpcObject.class); if (e && !seen.has(e.id)) { seen.add(e.id); out.push(e) } }
        return out
    }
    readonly property var items: pinned.concat(running)
    readonly property string focusedId: { const a = Hyprland.activeToplevel; const e = a && a.lastIpcObject ? entryFor(a.lastIpcObject.class) : null; return e ? e.id : "" }
    function isPinned(e) { return pinned.some(p => p.id === e.id) }

    function savePins(entries) { s.dockPinned = entries.map(e => e.id); Settings.save() }
    function togglePin(e) { savePins(isPinned(e) ? pinned.filter(p => p.id !== e.id) : pinned.concat([e])) }
    // drag-and-drop: put `e` at position `to` among the pinned apps (pins it if needed)
    function moveTo(e, to) {
        const list = pinned.filter(p => p.id !== e.id)
        list.splice(Math.max(0, Math.min(to, list.length)), 0, e)
        savePins(list)
    }
    function focus(t) { Hyprland.dispatch(`hl.dsp.focus({ window = "address:${t.lastIpcObject.address}" })`) }
    function activate(e) {
        const w = windowsOf(e)
        if (w.length === 0) { launch(e); return }
        const i = w.indexOf(Hyprland.activeToplevel)          // already focused? go to its next window
        focus(w[(i + 1) % w.length])
    }
    property string launching: ""                              // app id bouncing while it starts
    function launch(e) { launching = e.id; e.execute(); bounceStop.restart() }
    Timer { id: bounceStop; interval: 2500; onTriggered: dock.launching = "" }
    onWindowsChanged: if (launching && items.some(e => e.id === launching && windowsOf(e).length)) launching = ""
    function closeAll(e) { for (const t of windowsOf(e)) Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${t.lastIpcObject.address}" })`) }
    Component.onCompleted: Hyprland.refreshToplevels()

    // ---- the dock -----------------------------------------------------------------------------
    Variants {
        model: s.dock ? Quickshell.screens : []
        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            readonly property int icon: s.dockSize
            readonly property real cell: icon + 10
            property real mouseX: -1                          // pointer x over the row (for magnification)
            property var dragging: null                       // entry being dragged
            property real dragX: 0
            property var menuFor: null                        // entry whose menu is open
            property Item menuAnchor: null
            readonly property bool shown: !s.dockAutohide || hover.containsMouse || dragging !== null || menuFor !== null
            color: "transparent"
            anchors { bottom: true }
            implicitWidth: Math.max(row.width + 40, 200)
            implicitHeight: icon * 1.5 + 40 + s.dockMargin      // room for magnified icons and the name
            exclusionMode: s.dockAutohide ? ExclusionMode.Ignore : ExclusionMode.Auto
            exclusiveZone: s.dockAutohide ? 0 : icon + 16 + s.dockMargin
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "paleos-dock"
            // only the dock itself (or a thin strip when hidden) takes the mouse
            mask: Region { item: bar.shown ? hitArea : edge }

            Item { id: edge; anchors.bottom: parent.bottom; width: parent.width; height: 3 }
            Item { id: hitArea; anchors.bottom: parent.bottom; width: parent.width; height: card.height + s.dockMargin + bar.icon * 0.5 }
            MouseArea {
                id: hover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
                onPositionChanged: m => bar.mouseX = mapToItem(row, m.x, m.y).x
                onExited: bar.mouseX = -1
            }

            Rectangle {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                y: bar.shown ? parent.height - height - s.dockMargin : parent.height + 6
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                width: row.width + 20; height: bar.icon + 18
                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: s.dockRadius
                color: Qt.rgba(0.055, 0.055, 0.055, s.dockOpacity)
                border.color: Qt.rgba(1, 1, 1, 0.09 * s.dockOpacity)

                Row {
                    id: row
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                    spacing: s.dockSpacing
                    move: Transition { NumberAnimation { properties: "x"; duration: 180; easing.type: Easing.OutCubic } }

                    Tile { glyph: 0xF003B; label: "Apps"; onPrimary: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/launcher"]) }
                    Rectangle { width: 1; height: bar.icon * 0.6; anchors.bottom: parent.bottom; anchors.bottomMargin: bar.icon * 0.2; color: Theme.border }
                    Repeater {
                        model: dock.items
                        delegate: Tile {
                            required property var modelData
                            required property int index
                            entry: modelData
                            label: modelData.name
                            open: dock.windowsOf(modelData).length
                            focused: dock.focusedId === modelData.id
                            bouncing: dock.launching === modelData.id
                            onPrimary: dock.activate(modelData)
                            onSecondary: { bar.menuFor = modelData; bar.menuAnchor = this }
                            onDropped: x => {
                                // where among the pinned apps did it land?
                                let to = 0
                                for (let i = 0; i < dock.pinned.length; i++) if (x > row.children[i + 2].x + bar.cell / 2) to = i + 1
                                dock.moveTo(modelData, dock.pinned.some(p => p.id === modelData.id) && to > dock.pinned.findIndex(p => p.id === modelData.id) ? to - 1 : to)
                            }
                        }
                    }
                }
            }

            // ---- right-click menu ----
            PopupWindow {
                id: menu
                visible: bar.menuFor !== null
                anchor.item: bar.menuAnchor
                anchor.edges: Edges.Top
                anchor.gravity: Edges.Top
                anchor.margins.top: -10
                implicitWidth: 200; implicitHeight: col.implicitHeight + 12
                color: "transparent"
                HyprlandFocusGrab { active: menu.visible; windows: [menu]; onCleared: bar.menuFor = null }
                Rectangle {
                    anchors.fill: parent; radius: 12; color: Theme.bg; border.color: Theme.border
                    Column {
                        id: col; x: 6; y: 6; width: parent.width - 12; spacing: 2
                        Row {   // which app this menu is for
                            spacing: 10; leftPadding: 8; topPadding: 6; bottomPadding: 8
                            Image { width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter; smooth: true; mipmap: true
                                    source: bar.menuFor ? Quickshell.iconPath(bar.menuFor.icon, "application-x-executable") : "" }
                            Text { anchors.verticalCenter: parent.verticalCenter; width: col.width - 50; elide: Text.ElideRight
                                   text: bar.menuFor ? bar.menuFor.name : ""; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                        }
                        Rectangle { width: parent.width; height: 1; color: Theme.border }
                        Repeater {
                            model: {
                                const e = bar.menuFor; if (!e) return []
                                const open = dock.windowsOf(e).length
                                return [ open ? { g: 0xF0415, t: "New window", a: "new" } : { g: 0xF040A, t: "Open", a: "open" },
                                         dock.isPinned(e) ? { g: 0xF0931, t: "Unpin from dock", a: "pin" } : { g: 0xF0403, t: "Pin to dock", a: "pin" } ]
                                       .concat(open ? [{ g: 0xF0156, t: open > 1 ? "Close all windows" : "Close", a: "close" }] : [])
                            }
                            delegate: Entry {
                                required property var modelData
                                glyph: modelData.g; text: modelData.t
                                onClicked: {
                                    const e = bar.menuFor; bar.menuFor = null
                                    if (modelData.a === "open" || modelData.a === "new") dock.launch(e)
                                    else if (modelData.a === "pin") dock.togglePin(e)
                                    else if (modelData.a === "close") dock.closeAll(e)
                                }
                            }
                        }
                    }
                }
            }

            // ---- one icon ----
            component Tile: Item {
                id: tile
                property var entry: null
                property int glyph: 0
                property string label: ""
                property int open: 0
                property bool focused: false
                property bool bouncing: false
                signal primary()
                signal secondary()
                signal dropped(real x)
                // magnification: grows as the pointer gets close, neighbours a little
                readonly property real dist: bar.mouseX < 0 || bar.dragging ? 999 : Math.abs(bar.mouseX - (x + width / 2))
                readonly property real zoom: 1 + 0.32 * Math.max(0, 1 - dist / (bar.cell * 1.8))
                width: bar.cell * zoom; height: bar.cell * zoom
                Behavior on width { NumberAnimation { duration: 90 } }
                Behavior on height { NumberAnimation { duration: 90 } }
                property real bounce: 0
                SequentialAnimation on bounce {
                    running: tile.bouncing; loops: Animation.Infinite
                    NumberAnimation { to: -bar.icon * 0.35; duration: 260; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 0; duration: 260; easing.type: Easing.InQuad }
                    onStopped: tile.bounce = 0
                }
                property real shift: 0                       // horizontal offset while being dragged
                z: shift !== 0 ? 10 : 0
                transform: Translate { x: tile.shift; y: tile.bounce }

                Item {
                    anchors.fill: parent; anchors.margins: 5 * tile.zoom
                    opacity: ma.pressed && tile.shift === 0 ? 0.75 : 1
                    Image {
                        visible: tile.entry !== null; anchors.fill: parent
                        source: tile.entry ? Quickshell.iconPath(tile.entry.icon, "application-x-executable") : ""
                        sourceSize.width: bar.icon * 3; sourceSize.height: bar.icon * 3
                        smooth: true; mipmap: true; asynchronous: true
                    }
                    Text {
                        visible: tile.entry === null; anchors.centerIn: parent
                        text: Theme.icon(tile.glyph); color: Theme.fg; font.family: Theme.font; font.pixelSize: parent.width * 0.6
                    }
                }
                Row {   // open windows: dots; the focused app gets a wider pill
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: -3
                    spacing: 3
                    visible: Settings.data.dockDots
                    Repeater {
                        model: Math.min(3, tile.open)
                        delegate: Rectangle {
                            required property int index
                            width: tile.focused && index === 0 ? 12 : 4; height: 4; radius: 2
                            color: Theme.fg; opacity: tile.focused ? 1 : 0.55
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                }
                Rectangle {   // name, fades in
                    opacity: ma.containsMouse && tile.shift === 0 && !bar.menuFor ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.top; anchors.bottomMargin: 6
                    width: tip.implicitWidth + 16; height: 24; radius: 7; color: Theme.bg; border.color: Theme.border
                    Text { id: tip; anchors.centerIn: parent; text: tile.label; color: Theme.fg; font.family: Theme.font; font.pixelSize: 11 }
                }
                MouseArea {
                    id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: tile.shift !== 0 ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    preventStealing: true
                    property real startX: 0
                    onPressed: m => { startX = m.x }
                    onPositionChanged: m => {
                        if (!pressed || tile.entry === null || !(m.buttons & Qt.LeftButton)) return
                        if (tile.shift === 0 && Math.abs(m.x - startX) < 8) return
                        tile.shift = m.x - startX; bar.dragging = tile.entry
                    }
                    onReleased: m => {
                        if (tile.shift !== 0) {
                            const center = tile.x + tile.width / 2 + tile.shift
                            tile.shift = 0; bar.dragging = null
                            tile.dropped(center)
                        } else if (m.button === Qt.RightButton) tile.secondary()
                        else tile.primary()
                    }
                }
            }
        }
    }
}
