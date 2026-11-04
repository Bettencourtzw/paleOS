import QtQuick
import Quickshell
import Quickshell.Bluetooth

Panel {
    id: p
    readonly property var ad: Bluetooth.defaultAdapter
    onOpenChanged: if (!open && ad && ad.discovering) ad.discovering = false   // scanning costs battery, can stutter audio
    readonly property var devs: ad ? ad.devices.values
        .filter(d => d.paired || d.connected || ad.discovering)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)) : []
    readonly property int connectedCount: devs.filter(d => d.connected).length

    title: "Bluetooth"
    glyph: ad && ad.enabled ? (connectedCount > 0 ? 0xF00B1 : 0xF00AF) : 0xF00B2
    subtitle: !ad ? "No adapter" : !ad.enabled ? "Off" : connectedCount + " connected"

    Switcher { text: "Bluetooth"; checked: p.ad ? p.ad.enabled : false; onToggled: if (p.ad) p.ad.enabled = !p.ad.enabled }

    Heading { text: "DEVICES"; visible: p.ad && p.ad.enabled }
    Column {
        width: parent.width; spacing: 2
        visible: p.ad && p.ad.enabled
        Repeater {
            model: p.devs
            delegate: Entry {
                required property var modelData
                glyph: 0xF00AF
                text: modelData.name || modelData.deviceName || modelData.address
                active: modelData.connected
                detail: modelData.pairing ? "Pairing…" : modelData.connected
                        ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "Connected")
                        : modelData.paired ? "" : "Pair"
                onClicked: {
                    if (modelData.connected) modelData.disconnect()
                    else if (modelData.paired) modelData.connect()
                    else { modelData.trusted = true; modelData.pair() }
                }
            }
        }
        Text { visible: p.devs.length === 0; text: "No devices yet"; color: Theme.dim; font.family: Theme.font; font.pixelSize: 12; leftPadding: 10 }
        Entry {
            glyph: 0xF0349
            text: p.ad && p.ad.discovering ? "Stop scanning" : "Scan for devices"
            onClicked: if (p.ad) p.ad.discovering = !p.ad.discovering
        }
    }
}
