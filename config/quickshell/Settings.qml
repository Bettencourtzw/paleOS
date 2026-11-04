pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// paleOS settings, shared by Customize, Power settings and the background.
// Stored in ~/.config/paleos/settings.json; ~/.local/bin/paleos-apply turns it into config files.
Singleton {
    readonly property alias data: adapter
    function save() { file.writeAdapter() }
    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/paleos/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: writeAdapter()          // first run: write the defaults
        JsonAdapter {
            id: adapter
            // background
            property string background: "static"  // "static", a built-in (e.g. "arch-pulse") or "video:/path"
            property int bgFps: 30                 // frames per second for animated backgrounds
            property real bgSpeed: 1.0             // 0.25 … 2
            property real bgBrightness: 1.0        // 0.4 … 1.2
            property bool pauseFullscreen: true    // freeze while an app is fullscreen
            property bool pauseWindows: false      // freeze while windows are open on that desktop
            property string animate: ""            // old setting, migrated to pauseWindows
            // dock
            property bool dock: true
            property bool dockAutohide: false
            property int dockSize: 44
            property real dockOpacity: 0.92
            property int dockRadius: 14
            property int dockSpacing: 6
            property int dockMargin: 8
            property bool dockDots: true
            property var dockPinned: ["org.gnome.Nautilus.desktop", "foot.desktop", "firefox.desktop", "chromium.desktop"]   // missing apps are skipped
            // windows + bar
            property string barPosition: "top"
            property int gaps: 12
            property int rounding: 10
            property int borderSize: 2
            property bool blur: true
            property bool animations: true
            property bool windowHeaders: true     // header with buttons when pointing at a window's top edge
            property int headerHeight: 32         // 24 … 44
            property real headerOpacity: 0.94     // 0.3 … 1
            property int headerDelay: 350         // ms it stays after the pointer leaves, 100 … 1500
            // buttons, stored as "hide" so a settings file from before these options shows them all
            property bool headerHideFloat: false
            property bool headerHideFullscreen: false
            property bool headerHideClose: false
            // power (edited in Power settings)
            property int screensaverMinutes: 5
            property int lockMinutes: 10
            property int suspendMinutes: 0
        }
    }
}
