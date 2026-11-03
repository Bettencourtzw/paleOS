import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Panel {
    id: p
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    function nice(n) {
        if (!n) return "No output"
        const d = n.description || n.nickname || n.name
        if (/HDMI|DisplayPort|DP/i.test(d)) return "Monitor (HDMI)"
        if (/Analog/i.test(d)) return "Speakers (Line Out)"
        return d
    }
    function pct(n) { return n && n.audio ? Math.round(n.audio.volume * 100) + "%" : "" }

    title: "Sound"
    glyph: sink && sink.audio && sink.audio.muted ? 0xF0581 : 0xF057E
    subtitle: nice(sink)

    PwObjectTracker { objects: [ p.sink, p.source ] }

    Heading { text: "VOLUME"; value: p.sink && p.sink.audio && p.sink.audio.muted ? "Muted" : p.pct(p.sink) }
    Row {
        width: parent.width; spacing: 12
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.icon(p.sink && p.sink.audio && p.sink.audio.muted ? 0xF0581 : 0xF057E)
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 18
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (p.sink && p.sink.audio) p.sink.audio.muted = !p.sink.audio.muted }
        }
        Level {
            width: parent.width - 32
            value: p.sink && p.sink.audio ? Math.min(1, p.sink.audio.volume) : 0
            onMoved: v => { if (p.sink && p.sink.audio) { p.sink.audio.muted = false; p.sink.audio.volume = v } }
        }
    }

    Heading { text: "OUTPUT" }
    Column {
        width: parent.width; spacing: 2
        Repeater {
            model: p.outputs
            delegate: Entry {
                required property var modelData
                glyph: /HDMI|DisplayPort/i.test(modelData.description) ? 0xF0379 : 0xF04C3
                text: p.nice(modelData)
                active: modelData === p.sink
                detail: active ? "In use" : ""
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
    }

    Heading { text: "MICROPHONE"; value: p.source && p.source.audio && p.source.audio.muted ? "Muted" : p.pct(p.source) }
    Row {
        width: parent.width; spacing: 12
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.icon(p.source && p.source.audio && p.source.audio.muted ? 0xF036D : 0xF036C)
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 18
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (p.source && p.source.audio) p.source.audio.muted = !p.source.audio.muted }
        }
        Level {
            width: parent.width - 32
            value: p.source && p.source.audio ? Math.min(1, p.source.audio.volume) : 0
            onMoved: v => { if (p.source && p.source.audio) { p.source.audio.muted = false; p.source.audio.volume = v } }
        }
    }
}
