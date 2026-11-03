import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// A popup card under the top-right of the bar. Closes on outside click or Esc.
PanelWindow {
    id: win
    required property string title
    required property string subtitle
    required property int glyph
    property bool open: false
    signal closeRequested()
    default property alias content: body.data

    visible: open
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: 46; right: 10 }
    implicitWidth: 380
    implicitHeight: card.height
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "bar-popup"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab { active: win.open; windows: [ win ]; onCleared: win.closeRequested() }

    Rectangle {
        id: card
        width: parent.width
        height: col.implicitHeight + 32
        radius: 14
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        focus: true
        Keys.onEscapePressed: win.closeRequested()

        Column {
            id: col
            x: 16; y: 16
            width: parent.width - 32
            spacing: 14

            Row {
                spacing: 14
                Text { text: Theme.icon(win.glyph); color: Theme.fg; font.family: Theme.font; font.pixelSize: 26; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: win.title; color: Theme.fg; font.family: Theme.font; font.pixelSize: 15; font.bold: true }
                    Text { text: win.subtitle.toUpperCase(); color: Theme.dim; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1; elide: Text.ElideRight; width: 280 }
                }
            }
            Column { id: body; width: parent.width; spacing: 12 }
        }
    }
}
