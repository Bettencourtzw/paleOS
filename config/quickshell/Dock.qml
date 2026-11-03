import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Dock at the bottom: an apps button, pinned apps, then open apps. Click to focus or launch,
// right-click to pin/unpin. Settings in Customize → Dock (on/off, auto-hide, icon size).
Scope {
    id: dock
    readonly property var s: Settings.data
    function save() { Settings.save() }

    // pinned desktop ids → entries (missing apps are skipped)
    function lookup(id) { return DesktopEntries.byId(id) || DesktopEntries.byId(id.replace(/\.desktop$/, "")) || DesktopEntries.heuristicLookup(id.replace(/\.desktop$/, "")) }
    // re-evaluated once the app list has loaded (it loads in the background)
    readonly property var pinned: { DesktopEntries.applications.values.length; return s.dockPinned.map(id => dock.lookup(id)).filter(e => e) }
    // open windows grouped by app
    readonly property var windows: Hyprland.toplevels.values.filter(t => t.lastIpcObject && t.lastIpcObject.class)
    function entryFor(cls) { return DesktopEntries.heuristicLookup(cls) }
    function windowsOf(entry) {
        const ids = [entry.id.toLowerCase(), (entry.startupClass || "").toLowerCase()]
        return windows.filter(t => { const c = (t.lastIpcObject.class || "").toLowerCase(); return ids.includes(c) || (entryFor(t.lastIpcObject.class) || {}).id === entry.id })
    }
    readonly property var running: {
        const seen = new Set(pinned.map(e => e.id)), out = []
        for (const t of windows) {
            const e = entryFor(t.lastIpcObject.class)
            if (e && !seen.has(e.id)) { seen.add(e.id); out.push(e) }
        }
        return out
    }
    function isPinned(e) { return pinned.some(p => p.id === e.id) }
    function togglePin(e) {
        s.dockPinned = isPinned(e) ? s.dockPinned.filter(id => { const p = lookup(id); return !p || p.id !== e.id }) : s.dockPinned.concat([e.id])
        save()
    }
    function activate(e) {
        const w = windowsOf(e)
        if (w.length === 0) { e.execute(); return }
        // already focused? go to the next window of the same app
        const active = Hyprland.activeToplevel, i = w.indexOf(active)
        const next = w[(i + 1) % w.length]
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${next.lastIpcObject.address}" })`)
    }
    Component.onCompleted: Hyprland.refreshToplevels()

    Variants {
        model: s.dock ? Quickshell.screens : []
        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            readonly property int icon: s.dockSize
            readonly property bool shown: !s.dockAutohide || hover.containsMouse
            color: "transparent"
            anchors { bottom: true }
            implicitWidth: row.width + 20
            implicitHeight: icon + 22 + s.dockMargin
            exclusionMode: s.dockAutohide ? ExclusionMode.Ignore : ExclusionMode.Auto
            exclusiveZone: s.dockAutohide ? 0 : icon + 16 + s.dockMargin
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "paleos-dock"
            // when auto-hidden, only a thin strip at the bottom edge reacts to the mouse
            mask: Region { item: bar.shown ? card : edge }

            Item { id: edge; anchors.bottom: parent.bottom; width: parent.width; height: 3 }
            MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

            Rectangle {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                y: bar.shown ? parent.height - height - s.dockMargin : parent.height + 4
                Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                width: row.width + 20; height: bar.icon + 18
                radius: s.dockRadius; color: Qt.rgba(0.055, 0.055, 0.055, s.dockOpacity)
                border.color: Qt.rgba(1, 1, 1, 0.09 * s.dockOpacity)

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: s.dockSpacing

                    Tile {   // apps button
                        size: bar.icon
                        glyph: 0xF003B
                        label: "Apps"
                        onPrimary: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/launcher"])
                    }
                    Rectangle { width: 1; height: bar.icon * 0.6; anchors.verticalCenter: parent.verticalCenter; color: Theme.border }
                    Repeater {
                        model: dock.pinned.concat(dock.running)
                        delegate: Tile {
                            required property var modelData
                            size: bar.icon
                            entry: modelData
                            label: modelData.name + (dock.isPinned(modelData) ? "" : "  ·  right-click to pin")
                            open: dock.windowsOf(modelData).length
                            onPrimary: dock.activate(modelData)
                            onSecondary: dock.togglePin(modelData)
                        }
                    }
                }
            }
        }
    }

    component Tile: Item {
        id: tile
        property int size: 44
        property var entry: null
        property int glyph: 0
        property string label: ""
        property int open: 0
        signal primary()
        signal secondary()
        width: size + 8; height: size + 8
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        Rectangle { anchors.fill: parent; radius: 10; color: ma.containsMouse ? Theme.hover : "transparent" }
        Image {
            visible: tile.entry !== null
            anchors.centerIn: parent; width: tile.size; height: tile.size
            source: tile.entry ? Quickshell.iconPath(tile.entry.icon, "application-x-executable") : ""
            sourceSize.width: tile.size * 2; sourceSize.height: tile.size * 2
            smooth: true; asynchronous: true
            scale: ma.pressed ? 0.9 : ma.containsMouse ? 1.08 : 1
            Behavior on scale { NumberAnimation { duration: 120 } }
        }
        Text {
            visible: tile.entry === null
            anchors.centerIn: parent; text: Theme.icon(tile.glyph); color: Theme.fg
            font.family: Theme.font; font.pixelSize: tile.size * 0.55
        }
        Row {   // open-window dots
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: -2
            spacing: 3
            Repeater { model: Settings.data.dockDots ? Math.min(3, tile.open) : 0; delegate: Rectangle { width: 4; height: 4; radius: 2; color: Theme.fg } }
        }
        Rectangle {   // name on hover
            visible: ma.containsMouse && tile.label !== ""
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.top; anchors.bottomMargin: 10
            width: tip.implicitWidth + 16; height: 24; radius: 7; color: Theme.bg; border.color: Theme.border
            Text { id: tip; anchors.centerIn: parent; text: tile.label; color: Theme.fg; font.family: Theme.font; font.pixelSize: 11 }
        }
        MouseArea {
            id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => m.button === Qt.RightButton ? tile.secondary() : tile.primary()
        }
    }
}
