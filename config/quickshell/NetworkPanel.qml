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
    readonly property var nets: wifi ? wifi.networks.values.slice().sort((a, b) => b.signalStrength - a.signalStrength).slice(0, 8) : []
    readonly property var current: nets.find(n => n.connected) || null
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
    Column {
        width: parent.width; spacing: 2
        visible: p.wifi !== null && Networking.wifiEnabled
        Repeater {
            model: p.nets
            delegate: Entry {
                required property var modelData
                readonly property real s: modelData.signalStrength > 1 ? modelData.signalStrength / 100 : modelData.signalStrength
                glyph: [0xF092F, 0xF091F, 0xF0922, 0xF0925, 0xF0928][Math.min(4, Math.floor(s * 5))]
                text: modelData.name
                active: modelData.connected
                detail: modelData.connected ? "Connected" : modelData.known ? "Saved"
                        : modelData.security === WifiSecurityType.Open ? "Open" : Theme.icon(0xF033E)
                onClicked: {
                    if (modelData.connected) modelData.disconnect()
                    else if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect()
                    else { p.asking = modelData; pass.text = ""; pass.forceActiveFocus() }
                }
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
