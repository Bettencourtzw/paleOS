import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Animated desktop background (one per monitor). Only shown when Settings → background is
// animated, and only *moving* while you can actually see the desktop:
//   never while a fullscreen app (e.g. a game) is open; by default also not while windows are open.
Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bg
            required property var modelData
            screen: modelData
            visible: Settings.data.background === "night"
            color: "#05060a"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "paleos-background"

            readonly property var ws: Hyprland.monitorFor(modelData)?.activeWorkspace ?? null
            readonly property bool seen: ws !== null && !ws.hasFullscreen
                && (Settings.data.animate === "always" || ws.toplevels.values.length === 0)

            NightSky { anchors.fill: parent; running: bg.visible && bg.seen }
        }
    }
}
