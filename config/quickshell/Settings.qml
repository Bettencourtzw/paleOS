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
            property string background: "static"   // "static" (wallpaper image) or "night" (animated)
            property string animate: "visible"     // "visible": only on an empty desktop · "always": unless fullscreen
            property string barPosition: "top"
            property int gaps: 12
            property int rounding: 10
            property bool animations: true
            property int screensaverMinutes: 5
            property int lockMinutes: 10
        }
    }
}
