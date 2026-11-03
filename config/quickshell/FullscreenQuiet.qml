// No notification pop-ups while an app is fullscreen on any screen (games, videos).
// Uses mako's "fullscreen" mode (see ~/.config/mako/config); your own do-not-disturb is left alone.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    readonly property bool fullscreen: Hyprland.monitors.values.some(m => m.activeWorkspace?.hasFullscreen ?? false)
    function apply() { mode.command = ["makoctl", "mode", fullscreen ? "-a" : "-r", "fullscreen"]; mode.running = true }
    onFullscreenChanged: apply()
    Component.onCompleted: apply()
    Process { id: mode }
}
