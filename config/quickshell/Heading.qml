import QtQuick
// Small uppercase section heading with a divider line above it
Column {
    property alias text: t.text
    property string value: ""
    width: parent ? parent.width : 0
    spacing: 10
    Rectangle { width: parent.width; height: 1; color: Theme.border }
    Item {
        width: parent.width; height: t.height
        Text { id: t; color: Theme.dim; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 1 }
        Text { anchors.right: parent.right; text: parent.parent.value; color: Theme.dim; font.family: Theme.font; font.pixelSize: 11 }
    }
}
