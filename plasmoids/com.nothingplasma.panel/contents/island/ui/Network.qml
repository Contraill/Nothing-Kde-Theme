// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// The closed island's connection: Wi-Fi signal bars, a cable, or a red
// crossed-out Wi-Fi while offline.
Item {
    implicitWidth: Net.connected && Net.isWifi ? signal.implicitWidth : glyph.implicitWidth
    implicitHeight: Math.max(signal.implicitHeight, glyph.implicitHeight)
    Text {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        visible: !Net.connected || !Net.isWifi
        text: Net.connected ? Icons.ethernet : Icons.wifiOff
        color: Net.connected ? Theme.fg : Theme.alert
        font.family: Theme.fontIcons
        font.pixelSize: 18
    }
    WifiSignal {
        id: signal
        anchors.verticalCenter: parent.verticalCenter
        visible: Net.connected && Net.isWifi
        strength: Net.signal_
    }
}
