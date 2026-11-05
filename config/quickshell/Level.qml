import QtQuick
// Simple slider 0..1. Drag, click or scroll. `released` fires when you let go.
Item {
    id: s
    property real value: 0
    property bool dragging: false
    property string accessibleName: "Level"
    readonly property real minimumValue: 0
    readonly property real maximumValue: 1
    readonly property real stepSize: 0.05
    signal moved(real v)
    signal released()
    width: parent ? parent.width : 200
    height: 18
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: accessibleName
    Accessible.description: Math.round(value * 100) + " percent"
    Accessible.focusable: true
    Accessible.focused: activeFocus
    Accessible.onIncreaseAction: s.step(stepSize)
    Accessible.onDecreaseAction: s.step(-stepSize)
    Keys.onLeftPressed: s.step(-stepSize)
    Keys.onDownPressed: s.step(-stepSize)
    Keys.onRightPressed: s.step(stepSize)
    Keys.onUpPressed: s.step(stepSize)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) { s.moved(0); event.accepted = true }
        else if (event.key === Qt.Key_End) { s.moved(1); event.accepted = true }
    }
    function set(x) { s.moved(Math.max(0, Math.min(1, x / width))) }
    function step(amount) { s.moved(Math.max(0, Math.min(1, s.value + amount))) }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.bgAlt }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * s.value; height: 4; radius: 2; color: Theme.fg }
    Rectangle {
        x: parent.width * s.value - 7
        anchors.verticalCenter: parent.verticalCenter
        width: 14; height: 14; radius: 7
        color: Theme.fg
        border.width: s.activeFocus ? 2 : 0
        border.color: Theme.bg
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true          // the page can't steal the drag and start scrolling
        onPressed: e => { s.forceActiveFocus(); s.dragging = true; s.set(e.x) }
        onPositionChanged: e => { if (pressed) s.set(e.x) }
        onReleased: { s.dragging = false; s.released() }
        onCanceled: { s.dragging = false; s.released() }
        onWheel: e => s.step(e.angleDelta.y > 0 ? s.stepSize : -s.stepSize)
    }
}
