import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Networking
import Quickshell.Io

Panel {
    id: p
    readonly property var devs: Networking.devices.values
    readonly property var wired: devs.find(d => d.type === DeviceType.Wired) || null
    readonly property var wifi: devs.find(d => d.type === DeviceType.Wifi) || null
    readonly property var nets: wifi ? wifi.networks.values.slice().sort((a, b) => b.signalStrength - a.signalStrength) : []
    readonly property var current: wifi ? (wifi.networks.values.find(n => n.connected) || null) : null
    property var asking: null   // network waiting for a password
    property string ping: "–"
    property string down: "–"
    property string up: "–"
    Process {
        id: speed
        command: ["bash", "-c", "~/.local/bin/speedtest"]
        stdout: SplitParser { onRead: line => {
            const [k, v] = line.split(" ")
            if (k === "ping") p.ping = v + " ms"
            if (k === "down") { p.down = v + " Mbps"; p.up = "…" }
            if (k === "up") p.up = v + " Mbps"
            if (k === "error") { p.ping = "offline"; p.down = "–"; p.up = "–" }
        } }
    }
    function runSpeed() { if (speed.running) return; p.ping = "…"; p.down = "…"; p.up = "–"; speed.running = true }

    title: "Network"
    glyph: wired && wired.connected ? 0xF0200 : current ? 0xF0928 : 0xF092E
    subtitle: wired && wired.connected ? "Ethernet · connected" : current ? "Wi-Fi · " + current.name : "Not connected"
    onOpenChanged: if (!open) asking = null

    // scan for Wi-Fi only while the panel is open
    Binding { target: p.wifi; property: "scannerEnabled"; value: p.open; when: p.wifi !== null }

    Heading { text: "ETHERNET"; visible: p.wired !== null }
    Entry {
        visible: p.wired !== null
        glyph: 0xF0200
        text: "Wired connection"
        active: p.wired && p.wired.connected
        detail: p.wired && p.wired.connected ? "Connected" : "Unplugged"
    }

    Heading { text: "WI-FI"; visible: p.wifi !== null }
    Switcher { visible: p.wifi !== null; text: "Wi-Fi"; checked: Networking.wifiEnabled; onToggled: Networking.wifiEnabled = !Networking.wifiEnabled }
    ListView {
        id: networkList
        width: parent.width
        height: visible ? Math.min(contentHeight, 318) : 0
        visible: p.wifi !== null && Networking.wifiEnabled
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: p.nets
        currentIndex: -1
        onCountChanged: {
            if (count < 1) currentIndex = -1
            else if (currentIndex < 0) currentIndex = 0
            else if (currentIndex >= count) currentIndex = count - 1
        }
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        readonly property int pageSize: Math.max(1, Math.floor(height / 40))
        function focusNetwork(index) {
            if (count < 1) return
            currentIndex = Math.max(0, Math.min(count - 1, index))
            positionViewAtIndex(currentIndex, ListView.Contain)
            if (currentItem) currentItem.forceActiveFocus()
            else Qt.callLater(() => networkList.focusCurrentItem())
        }
        function focusCurrentItem() {
            if (currentItem) currentItem.forceActiveFocus()
        }

        delegate: Entry {
            required property var modelData
            required property int index
            width: networkList.width - (networkList.contentHeight > networkList.height ? 8 : 0)
            readonly property real s: modelData.signalStrength > 1 ? modelData.signalStrength / 100 : modelData.signalStrength
            glyph: [0xF092F, 0xF091F, 0xF0922, 0xF0925, 0xF0928][Math.min(4, Math.floor(s * 5))]
            text: modelData.name
            active: modelData.connected
            detail: modelData.connected ? "Connected" : modelData.known ? "Saved"
                    : modelData.security === WifiSecurityType.Open ? "Open" : Theme.icon(0xF033E)
            onActiveFocusChanged: if (activeFocus) networkList.currentIndex = index
            onIndexChanged: if (activeFocus) networkList.currentIndex = index
            Keys.onUpPressed: networkList.focusNetwork(index - 1)
            Keys.onDownPressed: networkList.focusNetwork(index + 1)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Home) networkList.focusNetwork(0)
                else if (event.key === Qt.Key_End) networkList.focusNetwork(networkList.count - 1)
                else if (event.key === Qt.Key_PageUp) networkList.focusNetwork(index - networkList.pageSize)
                else if (event.key === Qt.Key_PageDown) networkList.focusNetwork(index + networkList.pageSize)
                else return
                event.accepted = true
            }
            onClicked: {
                if (modelData.connected) modelData.disconnect()
                else if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect()
                else { p.asking = modelData; pass.text = ""; pass.forceActiveFocus() }
            }
        }
    }
    TextField {
        id: pass
        visible: p.asking !== null
        width: parent.width; height: 40
        echoMode: TextInput.Password
        placeholderText: p.asking ? "Password for " + p.asking.name : ""
        placeholderTextColor: Theme.dim
        color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; leftPadding: 12
        background: Rectangle { radius: 9; color: Theme.bgAlt; border.color: Theme.border }
        onAccepted: { if (p.asking) p.asking.connectWithPsk(text); p.asking = null }
        Keys.onEscapePressed: p.asking = null
    }

    Heading { text: "SPEED TEST"; value: speed.running ? "Testing…" : "" }
    Row {
        width: parent.width
        Repeater {
            model: [ { k: "PING", v: p.ping }, { k: "DOWNLOAD", v: p.down }, { k: "UPLOAD", v: p.up } ]
            delegate: Column {
                required property var modelData
                width: parent.width / 3; spacing: 2
                Text { text: modelData.v; color: Theme.fg; font.family: Theme.font; font.pixelSize: 16; font.bold: true }
                Text { text: modelData.k; color: Theme.dim; font.family: Theme.font; font.pixelSize: 9; font.letterSpacing: 1 }
            }
        }
    }
    Entry { glyph: 0xF04C5; text: speed.running ? "Running…" : "Run speed test"; onClicked: p.runSpeed() }
}
