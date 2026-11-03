import QtQuick
import QtMultimedia

// Shows one background: a built-in animation (backgrounds/<Name>.qml) or your own video ("video:/path").
// Passes the user's frame rate, speed and brightness to it (each background sets its own detail). `running` false = frozen.
Item {
    id: v
    property string name: ""
    property bool running: false
    property int fps: Settings.data.bgFps
    property real speed: Settings.data.bgSpeed
    property real brightness: Settings.data.bgBrightness
    readonly property bool isVideo: name.startsWith("video:")
    // "arch-particles" -> backgrounds/ArchParticles.qml
    function file(n) { return n.split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join("") }

    Loader {
        id: loader
        anchors.fill: parent
        active: v.name !== "" && v.name !== "static"
        source: v.isVideo || !active ? "" : "backgrounds/" + v.file(v.name) + ".qml"
        sourceComponent: v.isVideo ? videoBg : undefined
        onLoaded: {
            item.running = Qt.binding(() => v.running)
            if ("fps" in item) item.fps = Qt.binding(() => v.fps)
            if ("speed" in item) item.speed = Qt.binding(() => v.speed)
        }
    }
    Rectangle {   // brightness: below 1 darkens, above 1 lifts slightly
        anchors.fill: parent
        color: v.brightness < 1 ? "black" : "white"
        opacity: v.brightness < 1 ? 1 - v.brightness : (v.brightness - 1) * 0.15
        visible: loader.active && v.brightness !== 1
    }
    Component {
        id: videoBg
        Rectangle {
            property bool running: false
            property real speed: 1
            color: "black"
            onRunningChanged: running ? vid.play() : vid.pause()
            Video {
                id: vid
                anchors.fill: parent
                source: "file://" + v.name.slice(6)
                loops: MediaPlayer.Infinite
                muted: true
                playbackRate: parent.speed
                fillMode: VideoOutput.PreserveAspectCrop
                Component.onCompleted: parent.running ? play() : pause()
            }
        }
    }
}
