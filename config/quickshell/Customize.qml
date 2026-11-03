import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io

// paleOS Customize app (SUPER+SPACE → Customize). Changes save + apply immediately.
FloatingWindow {
    id: win
    property bool open: false
    visible: open
    title: "Customize — paleOS"
    implicitWidth: 820; implicitHeight: 860
    color: Theme.bg
    onClosed: open = false

    readonly property var s: Settings.data
    readonly property string home: Quickshell.env("HOME")
    function set(key, value) { s[key] = value; Settings.save(); applyTimer.restart() }
    Timer { id: applyTimer; interval: 350; onTriggered: { apply.running = false; apply.running = true } }
    Process { id: apply; command: [win.home + "/.local/bin/paleos-apply"] }
    Shortcut { sequence: "Escape"; onActivated: win.open = false }

    // ---- what's available: built-in animations, your videos, your images --------------------
    readonly property var builtins: [
        { name: "arch-particles",     label: "Arch particles",     about: "Points gather into the logo, then drift apart" },
        { name: "arch-constellation", label: "Arch constellation", about: "The logo drawn in stars, slowly breathing" },
        { name: "arch-pulse",         label: "Arch pulse",         about: "The symbol with soft rings and orbits" },
        { name: "night",              label: "Night sky",          about: "Drifting clouds, stars, shooting stars" },
        { name: "aurora",             label: "Aurora",             about: "Soft bands of light, flowing" },
        { name: "waves",              label: "Waves",              about: "Thin lines like a slow map" },
        { name: "snow",               label: "Snow",               about: "Flakes falling at three depths" },
        { name: "fireflies",          label: "Fireflies",          about: "Glowing points floating and pulsing" }]
    property var videos: []
    property var images: []
    property string currentImage: ""
    readonly property var animated: builtins.concat(videos.map(f => ({ name: "video:" + f, label: f.split("/").pop().replace(/\.[^.]+$/, ""), about: "Your video" })))

    Process {
        id: scan; running: win.open
        command: ["bash", "-c", "shopt -s nullglob nocaseglob; mkdir -p ~/Wallpapers/live; for f in ~/Wallpapers/*.{png,jpg,jpeg,webp} ~/Wallpapers/*/*.{png,jpg,jpeg,webp}; do echo \"I $f\"; done; for f in ~/Wallpapers/live/*.{mp4,webm,mkv,mov}; do echo \"V $f\"; done; echo \"C $(readlink -f ~/.config/hypr/wallpaper)\""]
        stdout: StdioCollector { onStreamFinished: {
            const im = [], vi = []
            for (const l of this.text.trim().split("\n")) {
                if (l.startsWith("I ")) im.push(l.slice(2)); else if (l.startsWith("V ")) vi.push(l.slice(2)); else if (l.startsWith("C ")) win.currentImage = l.slice(2)
            }
            win.images = im; win.videos = vi
        } }
    }
    Process { id: run; onExited: { scan.running = false; scan.running = true } }
    function pickImage(f) {
        run.command = ["bash", "-c", 'ln -sfn "$1" ~/.config/hypr/wallpaper && { pkill -x hyprpaper; setsid -f hyprpaper >/dev/null 2>&1; }', "_", f]
        run.running = true; currentImage = f; set("background", "static")
    }

    FileDialog {   // add your own images (wallpapers) or videos (animated backgrounds)
        id: addFiles
        title: "Add images or videos"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Images and videos (*.png *.jpg *.jpeg *.webp *.mp4 *.webm *.mkv *.mov)"]
        onAccepted: {
            const files = selectedFiles.map(u => decodeURIComponent(u.toString().replace("file://", "")))
            run.command = ["bash", "-c", 'mkdir -p ~/Wallpapers/live; for f; do case "${f,,}" in *.mp4|*.webm|*.mkv|*.mov) cp -n "$f" ~/Wallpapers/live/ ;; *) cp -n "$f" ~/Wallpapers/ ;; esac; done', "_"].concat(files)
            run.running = true
        }
    }

    // ---- layout ---------------------------------------------------------------------------
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

            Heading { text: "BACKGROUND"; value: win.s.background === "static" ? "Wallpaper" : (win.animated.find(a => a.name === win.s.background) || { label: "" }).label }

            Rectangle {   // big live preview of what's selected
                width: parent.width; height: width * 9 / 16 * 0.62
                radius: 12; color: "black"; clip: true
                border.color: Theme.border
                Image {
                    anchors.fill: parent; visible: win.s.background === "static"
                    source: win.currentImage ? "file://" + win.currentImage : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true
                    sourceSize.width: 1280
                }
                BackgroundView {
                    anchors.fill: parent; anchors.margins: 1; visible: win.s.background !== "static"
                    name: win.open && win.s.background !== "static" ? win.s.background : ""
                    running: win.open
                }
            }

            Text { text: "ANIMATED  ·  point at one to preview it"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
            Flow {
                width: parent.width; spacing: 12
                Repeater {
                    model: win.animated
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        readonly property bool on: win.s.background === modelData.name
                        width: (col.width - 24) / 3; height: width * 9 / 16 + 46
                        radius: 12; color: Theme.bgAlt; clip: true
                        border.width: on ? 2 : 1; border.color: on ? Theme.fg : (hover.containsMouse ? Theme.dim : Theme.border)
                        scale: hover.containsMouse ? 1.03 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Rectangle {   // the live preview
                            x: 3; y: 3; width: parent.width - 6; height: (parent.width - 6) * 9 / 16
                            radius: 9; color: "black"; clip: true
                            BackgroundView { anchors.fill: parent; name: win.open ? card.modelData.name : ""; running: hover.containsMouse }
                        }
                        Rectangle {   // selected badge
                            visible: card.on
                            x: parent.width - width - 10; y: 10; width: 24; height: 24; radius: 12; color: Theme.fg
                            Text { anchors.centerIn: parent; text: Theme.icon(0xF012C); color: Theme.bg; font.family: Theme.font; font.pixelSize: 15 }
                        }
                        Column {
                            x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: parent.width - 24; spacing: 1
                            Text { width: parent.width; elide: Text.ElideRight; text: card.modelData.label; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
                            Text { width: parent.width; elide: Text.ElideRight; text: card.modelData.about; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10 }
                        }
                        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.set("background", card.modelData.name) }
                    }
                }
            }
            Choice {
                visible: win.s.background !== "static"
                options: [{ label: "Animate unless fullscreen", value: "always" }, { label: "Only on an empty desktop", value: "visible" }]
                current: win.s.animate
                onPicked: v => win.set("animate", v)
            }

            Text { text: "WALLPAPERS"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
            Flow {
                width: parent.width; spacing: 12
                Repeater {
                    model: win.images
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool on: win.s.background === "static" && modelData === win.currentImage
                        width: (col.width - 24) / 3; height: width * 9 / 16; radius: 10
                        color: Theme.bgAlt; border.width: on ? 2 : 1; border.color: on ? Theme.fg : Theme.border
                        Image { anchors.fill: parent; anchors.margins: 3; source: "file://" + parent.modelData; fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 320; asynchronous: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.pickImage(parent.modelData) }
                    }
                }
            }
            Entry { glyph: 0xF0415; text: "Add your own images or videos…"; detail: "videos become animated backgrounds"; onClicked: addFiles.open() }
            Entry { glyph: 0xF024B; text: "Open the wallpapers folder"; onClicked: Quickshell.execDetached(["nautilus", win.home + "/Wallpapers"]) }

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
            Entry { glyph: 0xF0379; text: "Display settings"; detail: "resolution, refresh rate, scale"; onClicked: Quickshell.execDetached(["qs", "ipc", "call", "panel", "toggle", "display"]) }
            Entry { glyph: 0xF0594; text: "Toggle night light"; onClicked: Quickshell.execDetached([win.home + "/.local/bin/toggle-nightlight"]) }
            Entry { glyph: 0xF03EB; text: "Edit bar colors"; onClicked: Quickshell.execDetached(["foot", "-e", "nvim", win.home + "/.config/waybar/colors.css"]) }
            Entry { glyph: 0xF03EB; text: "Edit menu colors"; onClicked: Quickshell.execDetached(["foot", "-e", "nvim", win.home + "/.config/rofi/colors.rasi"]) }
        }
    }
}
