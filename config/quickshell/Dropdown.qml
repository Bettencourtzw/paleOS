import QtQuick
import QtQuick.Controls

// Themed dropdown. model: list of strings
ComboBox {
    id: box
    width: parent ? parent.width : 200
    height: 36
    font.family: Theme.font
    font.pixelSize: 13
    background: Rectangle { radius: 9; color: box.hovered ? Theme.hover : Theme.bgAlt; border.color: box.popup.visible ? Theme.dim : Theme.border }
    contentItem: Text {
        leftPadding: 12; verticalAlignment: Text.AlignVCenter
        text: box.displayText; color: Theme.fg; font: box.font; elide: Text.ElideRight
    }
    indicator: Text {
        x: box.width - width - 12; anchors.verticalCenter: parent.verticalCenter
        text: Theme.icon(box.popup.visible ? 0xF0143 : 0xF0140); color: Theme.dim; font.family: Theme.font; font.pixelSize: 16
    }
    delegate: ItemDelegate {
        required property var modelData
        required property int index
        width: box.width
        highlighted: box.highlightedIndex === index
        contentItem: Text { text: modelData; color: index === box.currentIndex ? Theme.fg : "#bdbdbd"; font.family: Theme.font; font.pixelSize: 13; font.bold: index === box.currentIndex; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 7; color: parent.highlighted ? Theme.hover : "transparent" }
    }
    popup: Popup {
        y: box.height + 4; width: box.width; padding: 4
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 300)
        contentItem: ListView { clip: true; implicitHeight: contentHeight; model: box.popup.visible ? box.delegateModel : null; currentIndex: box.highlightedIndex }
        background: Rectangle { radius: 10; color: Theme.bg; border.color: Theme.border }
    }
}
