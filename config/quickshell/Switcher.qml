import QtQuick
// On/off switch row
Item {
    id: t
    property string text: ""
    property bool checked: false
    signal toggled()
    width: parent ? parent.width : 0
    height: 26
    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: text
    Accessible.checked: checked
    Accessible.onPressAction: toggled()
    Keys.onSpacePressed: toggled()
    Keys.onReturnPressed: toggled()
    Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 52; elide: Text.ElideRight; text: t.text; color: Theme.fg; font.family: Theme.font; font.pixelSize: 13 }
    Rectangle {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        width: 40; height: 22; radius: 11
        color: t.checked ? Theme.fg : Theme.bgAlt
        border.color: t.activeFocus ? Theme.fg : Theme.border
        Rectangle { width: 16; height: 16; radius: 8; anchors.verticalCenter: parent.verticalCenter; x: t.checked ? 21 : 3; color: t.checked ? Theme.bg : Theme.dim; Behavior on x { NumberAnimation { duration: 120 } } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { t.forceActiveFocus(); t.toggled() } }
}
