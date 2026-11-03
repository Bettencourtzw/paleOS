import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

// paleOS Customize app (SUPER+SPACE → Customize). Changes save + apply immediately.
FloatingWindow {
    id: win
    property bool open: false
    visible: open
    title: "Customize — paleOS"
    implicitWidth: 760; implicitHeight: 720
    color: Theme.bg
    onClosed: open = false

    readonly property var s: Settings.data
    readonly property string home: Quickshell.env("HOME")
    function set(key, value) { s[key] = value; Settings.save(); applyTimer.restart() }
    Timer { id: applyTimer; interval: 350; onTriggered: { apply.running = false; apply.running = true } }
    Process { id: apply; command: [win.home + "/.local/bin/paleos-apply"] }

    // wallpapers in ~/Wallpapers
    property var wallpapers: []
    property string current: ""
    Process { id: list; running: win.open
        command: ["bash", "-c", "find ~/Wallpapers -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort; echo CURRENT=$(readlink -f ~/.config/hypr/wallpaper)"]
        stdout: StdioCollector { onStreamFinished: {
            const l = this.text.trim().split("\n"); win.current = (l.pop() || "").replace("CURRENT=", ""); win.wallpapers = l
        } } }
    Process { id: setWall }
    function pickWallpaper(f) {
        setWall.command = ["bash", "-c", `ln -sfn "${f}" ~/.config/hypr/wallpaper && pkill -x hyprpaper; setsid -f hyprpaper >/dev/null 2>&1`]
        setWall.running = true; current = f; set("background", "static")
    }

    Shortcut { sequence: "Escape"; onActivated: win.open = false }

    Flickable {
        anchors.fill: parent; anchors.margins: 28
        contentHeight: col.implicitHeight; clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        Column {
            id: col
            width: parent.width; spacing: 14

            Row {
                spacing: 14
                Text { text: Theme.icon(0xF03D8); color: Theme.fg; font.family: Theme.font; font.pixelSize: 30 }
                Column {
                    Text { text: "Customize"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 20; font.bold: true }
                    Text { text: "CHANGES APPLY RIGHT AWAY"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
                }
            }

            Heading { text: "BACKGROUND" }
            Choice {
                options: [{ label: "Wallpaper", value: "static" }, { label: "Night sky (animated)", value: "night" }]
                current: win.s.background
                onPicked: v => win.set("background", v)
            }
            Choice {
                visible: win.s.background === "night"
                options: [{ label: "Animate on an empty desktop", value: "visible" }, { label: "Animate unless fullscreen", value: "always" }]
                current: win.s.animate
                onPicked: v => win.set("animate", v)
            }
            Flow {
                width: parent.width; spacing: 10
                visible: win.s.background === "static"
                Repeater {
                    model: win.wallpapers
                    delegate: Rectangle {
                        required property string modelData
                        width: (col.width - 30) / 4; height: width * 9 / 16; radius: 8
                        color: Theme.bgAlt; border.width: modelData === win.current ? 2 : 1
                        border.color: modelData === win.current ? Theme.fg : Theme.border
                        Image { anchors.fill: parent; anchors.margins: 3; source: "file://" + parent.modelData; fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 320; asynchronous: true; smooth: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.pickWallpaper(parent.modelData) }
                    }
                }
            }

            Heading { text: "TOP BAR" }
            Choice {
                options: [{ label: "Top", value: "top" }, { label: "Bottom", value: "bottom" }]
                current: win.s.barPosition
                onPicked: v => win.set("barPosition", v)
            }

            Heading { text: "WINDOWS"; value: "gaps " + win.s.gaps + " · corners " + win.s.rounding }
            Text { text: "Gaps"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
            Level { value: win.s.gaps / 24; onMoved: v => win.set("gaps", Math.round(v * 24)) }
            Text { text: "Rounded corners"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
            Level { value: win.s.rounding / 20; onMoved: v => win.set("rounding", Math.round(v * 20)) }
            Switcher { text: "Animations"; checked: win.s.animations; onToggled: win.set("animations", !win.s.animations) }

            Heading { text: "WHEN IDLE" }
            Text { text: "Screensaver after"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
            Choice {
                options: [{ label: "Off", value: 0 }, { label: "2 min", value: 2 }, { label: "5 min", value: 5 }, { label: "10 min", value: 10 }, { label: "20 min", value: 20 }]
                current: win.s.screensaverMinutes
                onPicked: v => win.set("screensaverMinutes", v)
            }
            Text { text: "Lock after"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
            Choice {
                options: [{ label: "Off", value: 0 }, { label: "5 min", value: 5 }, { label: "10 min", value: 10 }, { label: "15 min", value: 15 }, { label: "30 min", value: 30 }]
                current: win.s.lockMinutes
                onPicked: v => win.set("lockMinutes", v)
            }

            Heading { text: "MORE" }
            Entry { glyph: 0xF0594; text: "Toggle night light"; onClicked: Quickshell.execDetached([win.home + "/.local/bin/toggle-nightlight"]) }
            Entry { glyph: 0xF03EB; text: "Edit bar colors"; onClicked: Quickshell.execDetached(["foot", "-e", "nvim", win.home + "/.config/waybar/colors.css"]) }
            Entry { glyph: 0xF03EB; text: "Edit menu colors"; onClicked: Quickshell.execDetached(["foot", "-e", "nvim", win.home + "/.config/rofi/colors.rasi"]) }
        }
    }
}
