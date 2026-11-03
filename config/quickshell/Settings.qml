pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// paleOS settings, shared by the Customize app and the background.
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
            property string background: "static"   // "static" (wallpaper), a built-in (e.g. "arch-pulse", "night") or "video:/path"
            property string animate: "always"      // "always": unless an app is fullscreen · "visible": only on an empty desktop
            property string barPosition: "top"
            property int gaps: 12
            property int rounding: 10
            property bool animations: true
            property int screensaverMinutes: 5
            property int lockMinutes: 10
        }
    }
}
