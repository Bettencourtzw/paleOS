import QtQuick
import QtMultimedia

// Shows one background: a built-in animation (backgrounds/<Name>.qml) or your own video ("video:/path").
// `running` false = frozen (no CPU/GPU use). Used by the desktop, the Customize preview and thumbnails.
Item {
    id: v
    property string name: ""
    property bool running: false
    readonly property bool isVideo: name.startsWith("video:")
    // "arch-particles" -> backgrounds/ArchParticles.qml
    function file(n) { return n.split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join("") }

    Loader {
        anchors.fill: parent
        active: v.name !== "" && v.name !== "static"
        source: v.isVideo || !active ? "" : "backgrounds/" + v.file(v.name) + ".qml"
        sourceComponent: v.isVideo ? videoBg : undefined
        onLoaded: item.running = Qt.binding(() => v.running)
    }
    Component {
        id: videoBg
        Rectangle {
            property bool running: false
            color: "black"
            onRunningChanged: running ? vid.play() : vid.pause()
            Video {
                id: vid
                anchors.fill: parent
                source: "file://" + v.name.slice(6)
                loops: MediaPlayer.Infinite
                muted: true
                fillMode: VideoOutput.PreserveAspectCrop
                Component.onCompleted: parent.running ? play() : pause()
            }
        }
    }
}
