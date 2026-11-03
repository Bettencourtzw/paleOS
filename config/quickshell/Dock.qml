import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Dock at the bottom: an apps button, pinned apps, then open apps.
//   click: open / switch to the app      right-click: menu (open, new window, pin/unpin, close)
//   drag: reorder — the other icons slide aside live; drop an open app among the pinned ones to pin it
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

    // ---- menu state (shared by the dock and the menu layer) -----------------------------------
    property var menuFor: null
    property var menuScreen: null
    property real menuX: 0                                     // centre of the icon, screen coordinates
    property real menuBottom: 0                                // distance of the menu from the screen bottom

    Variants {
        model: s.dock ? Quickshell.screens : []
        Scope {
            id: perScreen
            required property var modelData

            // ---- the dock ----
            PanelWindow {
                id: bar
                screen: perScreen.modelData
                readonly property int icon: s.dockSize
                readonly property real cell: icon + 10
                readonly property real step: cell + s.dockSpacing
                // drag state
                property int dragFrom: -1
                property int dragTo: -1
                property real dragX: 0
                readonly property bool shown: !s.dockAutohide || hover.containsMouse || dragFrom >= 0 || dock.menuFor !== null
                color: "transparent"
                anchors { bottom: true }
                implicitWidth: card.width + 40
                implicitHeight: icon + 60 + s.dockMargin                 // room for the name above
                exclusionMode: s.dockAutohide ? ExclusionMode.Ignore : ExclusionMode.Auto
                exclusiveZone: s.dockAutohide ? 0 : icon + 16 + s.dockMargin
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "paleos-dock"
                mask: Region { item: bar.shown ? hitArea : edge }        // only the dock (or a thin strip) takes the mouse

                Item { id: edge; anchors.bottom: parent.bottom; width: parent.width; height: 3 }
                Item { id: hitArea; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: card.width; height: card.height + s.dockMargin }
                MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

                // where an icon sits; while dragging, the others slide aside to make room
                function slot(i) {
                    if (dragFrom < 0 || i === dragFrom) return i
                    if (dragFrom < dragTo && i > dragFrom && i <= dragTo) return i - 1
                    if (dragFrom > dragTo && i >= dragTo && i < dragFrom) return i + 1
                    return i
                }

                Rectangle {
                    id: card
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: bar.shown ? parent.height - height - s.dockMargin : parent.height + 6
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    width: lead.width + strip.width + 24; height: bar.icon + 18
                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    radius: s.dockRadius
                    color: Qt.rgba(0.055, 0.055, 0.055, s.dockOpacity)
                    border.color: Qt.rgba(1, 1, 1, 0.09 * s.dockOpacity)

                    Row {   // apps button + separator
                        id: lead
                        x: 10; anchors.verticalCenter: parent.verticalCenter
                        spacing: s.dockSpacing
                        Tile { glyph: 0xF003B; label: "Apps"; onPrimary: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/launcher"]) }
                        Rectangle { width: 1; height: bar.icon * 0.6; anchors.verticalCenter: parent.verticalCenter; color: Theme.border }
                        Item { width: 1; height: 1 }
                    }
                    Item {   // the apps, laid out by slot
                        id: strip
                        anchors.left: lead.right; anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, dock.items.length * bar.step - s.dockSpacing); height: bar.cell
                        Repeater {
                            model: dock.items
                            delegate: Tile {
                                id: t
                                required property var modelData
                                required property int index
                                readonly property bool dragged: bar.dragFrom === index
                                entry: modelData
                                label: modelData.name
                                open: dock.windowsOf(modelData).length
                                focused: dock.focusedId === modelData.id
                                bouncing: dock.launching === modelData.id
                                x: dragged ? bar.dragX : bar.slot(index) * bar.step
                                Behavior on x { enabled: !t.dragged; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                                z: dragged ? 10 : 0
                                lifted: dragged
                                onPrimary: dock.activate(modelData)
                                onSecondary: {
                                    const p = t.mapToItem(null, t.width / 2, 0)
                                    dock.menuX = (bar.screen.width - bar.width) / 2 + p.x
                                    dock.menuBottom = bar.height - card.y + 10
                                    dock.menuScreen = bar.screen
                                    dock.menuFor = modelData
                                }
                                onDragStarted: { bar.dragFrom = index; bar.dragTo = index; bar.dragX = x }
                                onDragMoved: dx => {
                                    // pinned apps stay among the pins; open apps may move into the pins
                                    const limit = dock.isPinned(modelData) ? dock.pinned.length - 1 : dock.pinned.length
                                    bar.dragX = Math.max(0, Math.min(index * bar.step + dx, limit * bar.step))
                                    bar.dragTo = Math.max(0, Math.min(Math.round(bar.dragX / bar.step), limit))
                                }
                                onDragEnded: {
                                    const to = bar.dragTo, from = bar.dragFrom
                                    bar.dragX = to * bar.step                // settle into the gap first…
                                    bar.dragFrom = -1; bar.dragTo = -1
                                    if (to !== from && to <= dock.pinned.length - (dock.isPinned(modelData) ? 1 : 0)) {
                                        const list = dock.pinned.filter(p => p.id !== modelData.id)
                                        list.splice(to, 0, modelData)
                                        dock.savePins(list)                 // …then save the new order
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
                    property bool lifted: false
                    signal primary()
                    signal secondary()
                    signal dragStarted()
                    signal dragMoved(real dx)
                    signal dragEnded()
                    width: bar.cell; height: bar.cell
                    property real bounce: 0
                    SequentialAnimation on bounce {
                        running: tile.bouncing; loops: Animation.Infinite
                        NumberAnimation { to: -bar.icon * 0.3; duration: 260; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 0; duration: 260; easing.type: Easing.InQuad }
                        onStopped: tile.bounce = 0
                    }
                    transform: Translate { y: tile.bounce + (tile.lifted ? -6 : 0) }

                    Rectangle {   // soft highlight on hover (icons never move)
                        anchors.fill: parent; radius: 10
                        color: ma.containsMouse && !tile.lifted ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Item {
                        anchors.fill: parent; anchors.margins: 5
                        scale: tile.lifted ? 1.1 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        opacity: ma.pressed && !tile.lifted ? 0.75 : 1
                        Image {
                            visible: tile.entry !== null; anchors.fill: parent
                            source: tile.entry ? Quickshell.iconPath(tile.entry.icon, "application-x-executable") : ""
                            sourceSize.width: bar.icon * 2; sourceSize.height: bar.icon * 2
                            smooth: true; mipmap: true; asynchronous: true
                        }
                        Text {
                            visible: tile.entry === null; anchors.centerIn: parent
                            text: Theme.icon(tile.glyph); color: Theme.fg; font.family: Theme.font; font.pixelSize: parent.width * 0.6
                        }
                    }
                    Row {   // open windows: dots; the app you're in gets a wider pill
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: -3
                        spacing: 3; visible: Settings.data.dockDots && !tile.lifted
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
                        opacity: ma.containsMouse && !tile.lifted && !dock.menuFor ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.top; anchors.bottomMargin: 10
                        width: tip.implicitWidth + 16; height: 24; radius: 7; color: Theme.bg; border.color: Theme.border
                        Text { id: tip; anchors.centerIn: parent; text: tile.label; color: Theme.fg; font.family: Theme.font; font.pixelSize: 11 }
                    }
                    MouseArea {
                        id: ma; anchors.fill: parent; hoverEnabled: true
                        cursorShape: tile.lifted ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        preventStealing: true
                        property real startX: 0
                        property bool moving: false
                        onPressed: m => { startX = mapToItem(null, m.x, 0).x; moving = false }
                        onPositionChanged: m => {
                            if (!pressed || tile.entry === null || !(m.buttons & Qt.LeftButton)) return
                            const dx = mapToItem(null, m.x, 0).x - startX
                            if (!moving && Math.abs(dx) < 6) return
                            if (!moving) { moving = true; tile.dragStarted() }
                            tile.dragMoved(dx)
                        }
                        onReleased: m => {
                            if (moving) { moving = false; tile.dragEnded() }
                            else if (m.button === Qt.RightButton) tile.secondary()
                            else tile.primary()
                        }
                    }
                }
            }

            // ---- right-click menu: its own layer, always centred above the icon; a click anywhere else closes it
            PanelWindow {
                id: layer
                screen: perScreen.modelData
                visible: dock.menuFor !== null && dock.menuScreen === perScreen.modelData
                color: "transparent"
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "paleos-dock-menu"
                WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: dock.menuFor = null }
                Rectangle {
                    id: menu
                    width: 210; height: col.implicitHeight + 12
                    x: Math.max(8, Math.min(layer.width - width - 8, dock.menuX - width / 2))
                    y: layer.height - dock.menuBottom - height
                    radius: 12; color: Theme.bg; border.color: Theme.border
                    focus: true
                    Keys.onEscapePressed: dock.menuFor = null
                    MouseArea { anchors.fill: parent }          // clicks inside don't close it
                    Column {
                        id: col; x: 6; y: 6; width: parent.width - 12; spacing: 2
                        Row {   // which app this menu is for
                            spacing: 10; leftPadding: 8; topPadding: 6; bottomPadding: 8
                            Image { width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter; smooth: true; mipmap: true
                                    source: dock.menuFor ? Quickshell.iconPath(dock.menuFor.icon, "application-x-executable") : "" }
                            Text { anchors.verticalCenter: parent.verticalCenter; width: col.width - 50; elide: Text.ElideRight
                                   text: dock.menuFor ? dock.menuFor.name : ""; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true }
                        }
                        Rectangle { width: parent.width; height: 1; color: Theme.border }
                        Repeater {
                            model: {
                                const e = dock.menuFor; if (!e) return []
                                const open = dock.windowsOf(e).length
                                return [ open ? { g: 0xF0415, t: "New window", a: "new" } : { g: 0xF040A, t: "Open", a: "open" },
                                         dock.isPinned(e) ? { g: 0xF0931, t: "Unpin from dock", a: "pin" } : { g: 0xF0403, t: "Pin to dock", a: "pin" } ]
                                       .concat(open ? [{ g: 0xF0156, t: open > 1 ? "Close all windows" : "Close", a: "close" }] : [])
                            }
                            delegate: Entry {
                                required property var modelData
                                glyph: modelData.g; text: modelData.t
                                onClicked: {
                                    // grab everything first: closing the menu destroys this item (and its name lookups)
                                    const d = dock, a = modelData.a, e = d.menuFor
                                    if (a === "open" || a === "new") d.launch(e)
                                    else if (a === "pin") d.togglePin(e)
                                    else if (a === "close") d.closeAll(e)
                                    d.menuFor = null
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
