import QtQuick
import "."

Row {
    id: root
    spacing: 4

    Text {
        visible: !Net.connected || !Net.isWifi
        anchors.verticalCenter: parent.verticalCenter
        text: !Net.connected ? Icons.wifiOff : Net.isWifi ? Icons.wifi : Icons.ethernet
        color: Net.connected ? Theme.fg : Theme.error
        font.family: Theme.fontIcons
        font.pixelSize: 18
    }

    WifiSignal {
        anchors.verticalCenter: parent.verticalCenter
        visible: Net.connected && Net.isWifi
        strength: Net.signal_
    }
}
