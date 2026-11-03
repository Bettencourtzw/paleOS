// One Quickshell process: password dialog + top-bar panels.
// Toggle a panel: qs ipc call panel toggle sound|bluetooth|network
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: shell
    property string current: ""
    property string lastClosed: ""
    property double closedAt: 0
    function close() { if (current !== "") { lastClosed = current; closedAt = Date.now() } current = "" }
    function toggle(name) {
        // clicking the bar icon of an open panel: the outside-click already closed it, don't reopen
        if (current === "" && lastClosed === name && Date.now() - closedAt < 350) return
        if (current === name) close(); else current = name
    }

    Polkit {}
    Background {}
    Customize { id: customize }
    SoundPanel     { open: shell.current === "sound";     onCloseRequested: shell.close() }
    BluetoothPanel { open: shell.current === "bluetooth"; onCloseRequested: shell.close() }
    NetworkPanel   { open: shell.current === "network";   onCloseRequested: shell.close() }
    DisplayPanel   { open: shell.current === "display";   onCloseRequested: shell.close() }
    PowerPanel     { open: shell.current === "power";     onCloseRequested: shell.close() }

    IpcHandler {
        target: "panel"
        function toggle(name: string): void { shell.toggle(name) }
        function close(): void { shell.close() }
    }
    IpcHandler {
        target: "customize"
        function open(): void { customize.open = true }
        function toggle(): void { customize.open = !customize.open }
        function page(n: int): void { customize.tab = n; customize.open = true }   // 0 background · 1 animation · 2 windows · 3 bar
    }
}
