import QtQuick
// A row of equal buttons, one selected (like Omarchy's scale picker)
Row {
    id: c
    property var options: []      // strings
    property string current: ""
    signal picked(string value)
    width: parent ? parent.width : 0
    spacing: 6
    Repeater {
        model: c.options
        delegate: Rectangle {
            required property string modelData
            width: (c.width - c.spacing * (c.options.length - 1)) / c.options.length
            height: 30; radius: 8
            color: modelData === c.current ? Theme.fg : (ma.containsMouse ? Theme.hover : Theme.bgAlt)
            border.color: Theme.border
            Text { anchors.centerIn: parent; text: parent.modelData; color: parent.modelData === c.current ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.picked(parent.modelData) }
        }
    }
}
