import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Animated desktop background (one per monitor). Only shown when Settings → background is
// animated, and only *moving* while you can actually see the desktop:
//   by default not while an app (e.g. a game) is fullscreen on that monitor's current workspace;
//   optionally also not while windows are open. Both are set in Customize → Animation.
Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bg
            required property var modelData
            screen: modelData
            // Settings → background: "static" (wallpaper), a built-in name (backgrounds/), or "video:/path"
            readonly property string name: Settings.data.background
            visible: name !== "static"
            color: "#05060a"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "paleos-background"

            readonly property var ws: Hyprland.monitorFor(modelData)?.activeWorkspace ?? null
            // pause rules (Customize → Animation)
            readonly property bool pauseWindows: Settings.data.pauseWindows || Settings.data.animate === "visible"
            readonly property bool seen: ws !== null
                && !(Settings.data.pauseFullscreen && ws.hasFullscreen)
                && !(pauseWindows && ws.toplevels.values.length > 0)

            BackgroundView { anchors.fill: parent; name: bg.visible ? bg.name : ""; running: bg.visible && bg.seen }
        }
    }
}
