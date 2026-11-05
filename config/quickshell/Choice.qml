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
            id: option
            required property var modelData
            readonly property bool on: modelData.value === c.current
            width: (c.width - c.spacing * (c.options.length - 1)) / c.options.length
            height: 32; radius: 8
            color: on ? Theme.fg : (ma.containsMouse ? Theme.hover : Theme.bgAlt)
            border.color: activeFocus ? (on ? Theme.bg : Theme.fg) : Theme.border
            activeFocusOnTab: true
            Accessible.role: Accessible.RadioButton
            Accessible.name: modelData.label
            Accessible.checked: on
            Accessible.focusable: true
            Accessible.focused: activeFocus
            Accessible.onPressAction: option.choose()
            Keys.onSpacePressed: option.choose()
            Keys.onReturnPressed: option.choose()
            Keys.onEnterPressed: option.choose()
            function choose() { c.picked(modelData.value) }
            Text { anchors.centerIn: parent; text: modelData.label; color: parent.on ? Theme.bg : Theme.fg; font.family: Theme.font; font.pixelSize: 12; font.bold: true }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { option.forceActiveFocus(); option.choose() }
            }
        }
    }
}
