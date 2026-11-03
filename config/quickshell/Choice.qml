import QtQuick
// A row of equal buttons, one selected.  options: [{ label, value }]
Row {
    id: c
    property var options: []
    property var current
    signal picked(var value)
    width: parent ? parent.width : 0
    spacing: 6
    Repeater {
        model: c.options
        delegate: Rectangle {
            required property var modelData
            readonly property bool on: modelData.value === c.current
            width: (c.width - c.spacing * (c.options.length - 1)) / c.options.length
            height: 32; radius: 8
            color: on ? Theme.fg : (ma.containsMouse ? Theme.hover : Theme.bgAlt)
            border.color: Theme.border
            Text { anchors.centerIn: parent; text: modelData.label; color: parent.on ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.picked(modelData.value) }
        }
    }
}
