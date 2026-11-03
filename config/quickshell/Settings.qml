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
            property real bgDetail: 1.0            // 0.5 … 1.5 (how many stars, flakes, particles…)
            property real bgBrightness: 1.0        // 0.4 … 1.2
            property bool pauseFullscreen: true    // freeze while an app is fullscreen
            property bool pauseWindows: false      // freeze while windows are open on that desktop
            property string animate: ""            // old setting, migrated to pauseWindows
            // windows + bar
            property string barPosition: "top"
            property int gaps: 12
            property int rounding: 10
            property int borderSize: 2
            property bool blur: true
            property bool animations: true
            // power (edited in Power settings)
            property int screensaverMinutes: 5
            property int lockMinutes: 10
            property int suspendMinutes: 0
        }
    }
}
