import QtQuick
// Simple slider 0..1. Drag, click or scroll. `released` fires when you let go.
Item {
    id: s
    property real value: 0
    property bool dragging: false
    signal moved(real v)
    signal released()
    width: parent ? parent.width : 200
    height: 18
    function set(x) { s.moved(Math.max(0, Math.min(1, x / width))) }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.bgAlt }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * s.value; height: 4; radius: 2; color: Theme.fg }
    Rectangle { x: parent.width * s.value - 7; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: Theme.fg }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true          // the page can't steal the drag and start scrolling
        onPressed: e => { s.dragging = true; s.set(e.x) }
        onPositionChanged: e => { if (pressed) s.set(e.x) }
        onReleased: { s.dragging = false; s.released() }
        onCanceled: { s.dragging = false; s.released() }
        onWheel: e => s.moved(Math.max(0, Math.min(1, s.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
