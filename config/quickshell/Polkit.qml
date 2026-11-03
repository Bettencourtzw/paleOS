// Password dialog (polkit agent) — modelled on Omarchy's: one compact card with a lock
// icon and the password inline, a small label above saying what needs permission,
// red flash + shake on a wrong password. Enter = submit, Esc = cancel.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Polkit

Scope {
    id: root
    readonly property color accent:  Theme.fg
    readonly property color errorC:  Theme.red
    readonly property int fieldH: 42
    readonly property int pad: 14

    property bool closing: false
    property bool submitted: false
    property bool errorFlash: false
    property int shake: 0
    readonly property var flow: agent.flow
    readonly property bool shown: agent.isActive || closing

    function refocus() { if (shown) input.forceActiveFocus() }
    function begin() { closeTimer.stop(); closing = false; submitted = false; input.text = ""; Qt.callLater(refocus) }
    function submit() {
        if (!flow || !flow.isResponseRequired || input.text === "") return
        submitted = true; errorFlash = false
        flow.submit(input.text); input.text = ""
    }
    function cancel() { input.text = ""; submitted = false; closing = true; closeTimer.restart(); if (flow) flow.cancelAuthenticationRequest() }
    function failed() { submitted = false; errorFlash = true; input.text = ""; errorTimer.restart(); shakeAnim.restart(); Qt.callLater(refocus) }

    Timer { id: closeTimer; interval: 250; onTriggered: { root.closing = false; root.submitted = false; root.errorFlash = false } }
    Timer { id: errorTimer; interval: 1200; onTriggered: root.errorFlash = false }
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: root; property: "shake"; to: -8; duration: 35; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shake"; to: 8;  duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shake"; to: 0;  duration: 55; easing.type: Easing.OutQuad }
    }

    PolkitAgent {
        id: agent
        onAuthenticationRequestStarted: root.begin()
    }
    Connections {
        target: root.flow
        function onIsResponseRequiredChanged() { if (root.flow && root.flow.isResponseRequired) root.submitted = false; Qt.callLater(root.refocus) }
        function onAuthenticationFailed() { root.failed() }
        function onAuthenticationSucceeded() { root.closing = true; closeTimer.restart() }
        function onAuthenticationRequestCancelled() { root.closing = true; closeTimer.restart() }
    }

    // Ctrl+V / Shift+Insert paste (reliable on overlay surfaces)
    Process {
        id: pasteProc
        command: ["wl-paste", "--no-newline", "--type", "text/plain"]
        stdout: StdioCollector { onStreamFinished: input.insert(input.cursorPosition, this.text) }
    }

    PanelWindow {
        id: win
        visible: root.shown
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "polkit"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle { anchors.fill: parent; color: "#99000000" }
        MouseArea { anchors.fill: parent; onClicked: root.refocus() }

        // what is asking for permission (or the lockout message)
        Rectangle {
            anchors.horizontalCenter: card.horizontalCenter
            anchors.bottom: card.top; anchors.bottomMargin: 10
            width: Math.min(label.implicitWidth + 24, win.width - 40); height: 28
            radius: 10; color: Theme.bg
            Text {
                id: label
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                elide: Text.ElideMiddle
                text: root.flow && root.flow.supplementaryMessage ? root.flow.supplementaryMessage
                      : root.flow && root.flow.message ? root.flow.message : "Authentication is needed"
                color: root.flow && root.flow.supplementaryIsError ? root.errorC : Theme.fg
                font.family: Theme.font; font.pixelSize: 12
            }
        }

        Rectangle {
            id: card
            width: 330; height: root.fieldH + root.pad * 2
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.shake
            radius: 12
            color: Theme.bg
            border.width: 1
            border.color: root.errorFlash ? root.errorC : Theme.border
            Behavior on border.color { ColorAnimation { duration: 120 } }
            MouseArea { anchors.fill: parent; onClicked: root.refocus() }

            Row {
                anchors.fill: parent; anchors.margins: root.pad
                spacing: 14

                Text {   // lock
                    width: 22; height: root.fieldH
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    text: Theme.icon(0xF033E)
                    color: root.errorFlash ? root.errorC : root.accent
                    font.family: Theme.font; font.pixelSize: 20
                }

                Item {
                    width: parent.width - 22 - 14; height: root.fieldH

                    TextInput {
                        id: input
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        activeFocusOnPress: true
                        font.family: Theme.font; font.pixelSize: 18
                        echoMode: (root.flow && root.flow.responseVisible) ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        color: root.errorFlash ? root.errorC : Theme.fg
                        selectionColor: "#55ffffff"
                        cursorVisible: activeFocus && !root.submitted && !root.errorFlash
                        readOnly: root.submitted || root.errorFlash
                        onAccepted: root.submit()
                        Keys.onPressed: e => {
                            if (e.key === Qt.Key_Escape) { root.cancel(); e.accepted = true }
                            else if ((e.key === Qt.Key_V && (e.modifiers & Qt.ControlModifier)) ||
                                     (e.key === Qt.Key_Insert && (e.modifiers & Qt.ShiftModifier))) { pasteProc.running = true; e.accepted = true }
                        }
                    }
                    Text {   // placeholder / status
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; elide: Text.ElideRight
                        visible: input.text.length === 0
                        text: root.errorFlash ? "Wrong password" : root.submitted ? "Checking…" : "Enter password"
                        color: root.errorFlash ? root.errorC : Theme.fg
                        opacity: root.errorFlash ? 1 : 0.36
                        font.family: Theme.font; font.pixelSize: 18
                    }
                    MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }
                }

            }
        }
    }
}
