import QtQuick
// One clickable row: icon, text, optional detail on the right
Rectangle {
    id: r
    property int glyph: 0
    property string text: ""
    property string detail: ""
    property bool active: false
    signal clicked()
    width: parent ? parent.width : 0
    height: 38
    radius: 9
    color: ma.containsMouse ? Theme.hover : (active ? Theme.bgAlt : "transparent")
    border.width: activeFocus ? 1 : 0
    border.color: Theme.fg
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.description: detail
    Accessible.focusable: true
    Accessible.focused: activeFocus
    Accessible.onPressAction: r.activate()
    Keys.onSpacePressed: r.activate()
    Keys.onReturnPressed: r.activate()
    Keys.onEnterPressed: r.activate()
    function activate() { r.clicked() }
    Text { visible: r.glyph > 0; x: 10; anchors.verticalCenter: parent.verticalCenter; text: Theme.icon(r.glyph); color: r.active ? Theme.fg : Theme.dim; font.family: Theme.font; font.pixelSize: 16 }
    Text {
        x: r.glyph > 0 ? 38 : 10; anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - det.width - 20; elide: Text.ElideRight
        text: r.text; color: r.active ? Theme.fg : "#bdbdbd"; font.family: Theme.font; font.pixelSize: 13; font.bold: r.active
    }
    Text { id: det; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: r.detail; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { r.forceActiveFocus(); r.activate() }
    }
}
