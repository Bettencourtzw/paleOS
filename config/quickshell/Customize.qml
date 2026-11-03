import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io

// paleOS Customize app (SUPER+SPACE → Customize). A normal tiled window with tabs.
// Every change saves to ~/.config/paleos/settings.json and applies right away.
FloatingWindow {
    id: win
    property bool open: false
    property int tab: 0
    visible: open
    title: "Customize — paleOS"
    implicitWidth: 960; implicitHeight: 760
    color: Theme.bg
    onClosed: open = false

    readonly property var s: Settings.data
    readonly property string home: Quickshell.env("HOME")
    function set(key, value) { s[key] = value; Settings.save(); applyTimer.restart() }
    Timer { id: applyTimer; interval: 350; onTriggered: { apply.running = false; apply.running = true } }
    Process { id: apply; command: [win.home + "/.local/bin/paleos-apply"] }
    Shortcut { sequence: "Escape"; onActivated: win.open = false }

    // ---- backgrounds: built-ins, your videos, your images ----------------------------------
    readonly property var builtins: [
        { name: "arch-binary",        label: "Arch binary",        about: "Deep black · the logo in flipping 0s and 1s" },
        { name: "arch-pulse",         label: "Arch pulse",         about: "Deep black · the symbol, orbits, ripples" },
        { name: "arch-particles",     label: "Arch particles",     about: "Deep black · particles spiral into the logo" },
        { name: "arch-constellation", label: "Arch constellation", about: "The logo traced in stars, in a cloudy sky" },
        { name: "night",              label: "Night sky",          about: "Drifting clouds, stars, shooting stars" },
        { name: "aurora",             label: "Aurora",             about: "Curtains of pale light" }]
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
    FileDialog {
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

    // small helpers for this window
    component Hint: Text { color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
    component Setting: Column {   // labelled slider: value in [from, to]
        id: sl
        property string text
        property real from: 0
        property real to: 1
        property real value: 0
        property string shown: value.toFixed(2)
        signal changed(real v)
        width: parent ? parent.width : 0; spacing: 8
        Item { width: parent.width; height: 14
            Hint { width: parent.width - value.width - 12; elide: Text.ElideRight; text: sl.text }
            Hint { id: value; anchors.right: parent.right; text: sl.shown; color: Theme.fg } }
        Level { width: parent.width; value: (sl.value - sl.from) / (sl.to - sl.from); onMoved: v => sl.changed(sl.from + v * (sl.to - sl.from)) }
    }
    component Card: Rectangle {   // an animated background card with live preview
        id: card
        property var item
        readonly property bool on: win.s.background === item.name
        width: (pane.width - 24) / 3; height: width * 9 / 16 + 46
        radius: 12; color: Theme.bgAlt; clip: true
        border.width: on ? 2 : 1; border.color: on ? Theme.fg : (hover.containsMouse ? Theme.dim : Theme.border)
        scale: hover.containsMouse ? 1.03 : 1
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Rectangle {
            x: 3; y: 3; width: parent.width - 6; height: (parent.width - 6) * 9 / 16; radius: 9; color: "black"; clip: true
            BackgroundView { anchors.fill: parent; name: win.open ? card.item.name : ""; running: hover.containsMouse }
        }
        Rectangle { visible: card.on; x: parent.width - width - 10; y: 10; width: 24; height: 24; radius: 12; color: Theme.fg
            Text { anchors.centerIn: parent; text: Theme.icon(0xF012C); color: Theme.bg; font.family: Theme.font; font.pixelSize: 15 } }
        Column { x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: parent.width - 24; spacing: 1
            Text { width: parent.width; elide: Text.ElideRight; text: card.item.label; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
            Text { width: parent.width; elide: Text.ElideRight; text: card.item.about; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10 } }
        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.set("background", card.item.name) }
    }
    component Preview: Rectangle {   // live preview of what's selected
        width: parent ? parent.width : 0; height: width * 9 / 16 * 0.55
        radius: 12; color: "black"; clip: true; border.color: Theme.border
        Image { anchors.fill: parent; anchors.margins: 1; visible: win.s.background === "static"
                source: win.currentImage ? "file://" + win.currentImage : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 1280 }
        BackgroundView { anchors.fill: parent; anchors.margins: 1; visible: win.s.background !== "static"
                         name: win.open && win.s.background !== "static" ? win.s.background : ""; running: win.open }
    }

    // ---- sidebar ----------------------------------------------------------------------------
    Rectangle {
        id: side
        width: 210; height: parent.height; color: "#0a0a0a"
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border }
        Column {
            x: 16; y: 24; width: parent.width - 32; spacing: 4
            Row { spacing: 12; bottomPadding: 18
                Text { text: Theme.icon(0xF03D8); color: Theme.fg; font.family: Theme.font; font.pixelSize: 24 }
                Text { text: "Customize"; color: Theme.fg; font.family: Theme.font; font.pixelSize: 17; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }
            Repeater {
                model: [ { g: 0xF02E9, t: "Background" }, { g: 0xF0E7B, t: "Animation" }, { g: 0xF05B2, t: "Windows" }, { g: 0xF06DF, t: "Top bar" }, { g: 0xF0E7A, t: "Dock" } ]
                delegate: Entry { required property var modelData; required property int index
                                  glyph: modelData.g; text: modelData.t; active: win.tab === index; onClicked: win.tab = index }
            }
        }
    }

    // ---- pages ------------------------------------------------------------------------------
    Flickable {
        id: flick
        anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 28 }
        contentHeight: pane.implicitHeight; clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        Column {
            id: pane
            width: flick.width; spacing: 14

            // Background ---------------------------------------------------------------------
            Column { visible: win.tab === 0; width: parent.width; spacing: 14
                Heading { text: "BACKGROUND"; value: win.s.background === "static" ? "Wallpaper" : (win.animated.find(a => a.name === win.s.background) || { label: "" }).label }
                Preview {}
                Hint { text: "ANIMATED  ·  point at one to preview it"; font.letterSpacing: 1; font.pixelSize: 10 }
                Flow { width: parent.width; spacing: 12
                    Repeater { model: win.animated; delegate: Card { required property var modelData; item: modelData } } }
                Hint { text: "WALLPAPERS"; font.letterSpacing: 1; font.pixelSize: 10 }
                Flow { width: parent.width; spacing: 12
                    Repeater { model: win.images
                        delegate: Rectangle { required property string modelData
                            readonly property bool on: win.s.background === "static" && modelData === win.currentImage
                            width: (pane.width - 24) / 3; height: width * 9 / 16; radius: 10
                            color: Theme.bgAlt; border.width: on ? 2 : 1; border.color: on ? Theme.fg : Theme.border
                            Image { anchors.fill: parent; anchors.margins: 3; source: "file://" + parent.modelData; fillMode: Image.PreserveAspectCrop; sourceSize.width: 320; asynchronous: true }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.pickImage(parent.modelData) } } } }
                Entry { glyph: 0xF0415; text: "Add your own images or videos…"; onClicked: addFiles.open() }
                Entry { glyph: 0xF024B; text: "Open the wallpapers folder"; onClicked: Quickshell.execDetached(["nautilus", win.home + "/Wallpapers"]) }
            }

            // Animation ------------------------------------------------------------------------
            Column { visible: win.tab === 1; width: parent.width; spacing: 16
                Heading { text: "ANIMATED BACKGROUND"; value: win.s.background === "static" ? "using a wallpaper" : "" }
                Preview {}
                Hint { text: "Frame rate" }
                Choice { options: [15, 24, 30, 45, 60].map(f => ({ label: f + " fps", value: f })); current: win.s.bgFps; onPicked: v => win.set("bgFps", v) }
                Setting { visible: win.s.background !== "static" && !win.s.background.startsWith("video:"); text: "Speed"; from: 0.25; to: 2; value: win.s.bgSpeed; shown: win.s.bgSpeed.toFixed(2) + "×"; onChanged: v => win.set("bgSpeed", Math.round(v * 20) / 20) }
                Setting { text: "Brightness"; from: 0.4; to: 1.2; value: win.s.bgBrightness; shown: Math.round(win.s.bgBrightness * 100) + "%"; onChanged: v => win.set("bgBrightness", Math.round(v * 20) / 20) }
                Heading { text: "WHEN TO PAUSE" }
                Switcher { text: "Pause while an app is fullscreen"; checked: win.s.pauseFullscreen; onToggled: win.set("pauseFullscreen", !win.s.pauseFullscreen) }
                Switcher { text: "Pause while windows are open"; checked: win.s.pauseWindows || win.s.animate === "visible"
                           onToggled: { const on = win.s.pauseWindows || win.s.animate === "visible"; win.set("animate", ""); win.set("pauseWindows", !on) } }
            }

            // Windows --------------------------------------------------------------------------
            Column { visible: win.tab === 2; width: parent.width; spacing: 16
                Heading { text: "WINDOWS" }
                Setting { text: "Border around the active window"; from: 0; to: 6; value: win.s.borderSize; shown: win.s.borderSize + " px"; onChanged: v => win.set("borderSize", Math.round(v)) }
                Setting { text: "Gaps between windows"; from: 0; to: 24; value: win.s.gaps; shown: win.s.gaps + " px"; onChanged: v => win.set("gaps", Math.round(v)) }
                Setting { text: "Rounded corners"; from: 0; to: 20; value: win.s.rounding; shown: win.s.rounding + " px"; onChanged: v => win.set("rounding", Math.round(v)) }
                Switcher { text: "Blur behind see-through windows"; checked: win.s.blur; onToggled: win.set("blur", !win.s.blur) }
                Switcher { text: "Animations"; checked: win.s.animations; onToggled: win.set("animations", !win.s.animations) }
            }

            // Dock -----------------------------------------------------------------------------
            Column { visible: win.tab === 4; width: parent.width; spacing: 16
                Heading { text: "DOCK" }
                Switcher { text: "Show the dock"; checked: win.s.dock; onToggled: win.set("dock", !win.s.dock) }
                Switcher { visible: win.s.dock; text: "Hide until the mouse reaches the bottom"; checked: win.s.dockAutohide; onToggled: win.set("dockAutohide", !win.s.dockAutohide) }
                Setting { visible: win.s.dock; text: "Icon size"; from: 28; to: 72; value: win.s.dockSize; shown: win.s.dockSize + " px"; onChanged: v => win.set("dockSize", Math.round(v / 2) * 2) }
                Setting { visible: win.s.dock; text: "Background opacity"; from: 0; to: 1; value: win.s.dockOpacity; shown: Math.round(win.s.dockOpacity * 100) + "%"; onChanged: v => win.set("dockOpacity", Math.round(v * 20) / 20) }
                Setting { visible: win.s.dock; text: "Rounded corners"; from: 0; to: 28; value: win.s.dockRadius; shown: win.s.dockRadius + " px"; onChanged: v => win.set("dockRadius", Math.round(v)) }
                Setting { visible: win.s.dock; text: "Space between icons"; from: 0; to: 20; value: win.s.dockSpacing; shown: win.s.dockSpacing + " px"; onChanged: v => win.set("dockSpacing", Math.round(v)) }
                Setting { visible: win.s.dock; text: "Distance from the bottom"; from: 0; to: 40; value: win.s.dockMargin; shown: win.s.dockMargin + " px"; onChanged: v => win.set("dockMargin", Math.round(v)) }
                Switcher { visible: win.s.dock; text: "Dots under open apps"; checked: win.s.dockDots; onToggled: win.set("dockDots", !win.s.dockDots) }
                Hint { visible: win.s.dock; width: parent.width; wrapMode: Text.WordWrap; text: "Right-click an app in the dock to pin or unpin it." }
            }

            // Top bar --------------------------------------------------------------------------
            Column { visible: win.tab === 3; width: parent.width; spacing: 16
                Heading { text: "TOP BAR" }
                Hint { text: "Position" }
                Choice { options: [{ label: "Top", value: "top" }, { label: "Bottom", value: "bottom" }]; current: win.s.barPosition; onPicked: v => win.set("barPosition", v) }
                Entry { glyph: 0xF06DF; text: "Show / hide the bar"; detail: "SUPER + SHIFT + SPACE"; onClicked: Quickshell.execDetached(["pkill", "-SIGUSR1", "waybar"]) }
                Entry { glyph: 0xF03EB; text: "Edit bar colors"; onClicked: Quickshell.execDetached(["foot", "-e", "nvim", win.home + "/.config/waybar/colors.css"]) }
                Entry { glyph: 0xF03EB; text: "Edit menu colors"; onClicked: Quickshell.execDetached(["foot", "-e", "nvim", win.home + "/.config/rofi/colors.rasi"]) }
            }
        }
    }
}
