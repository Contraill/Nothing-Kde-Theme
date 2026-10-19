// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// Four cards in two columns: network and Bluetooth switches that open their
// panels, the sound level with the microphone, and brightness.
Grid {
    id: root
    columns: 2
    spacing: 8

    signal requestPanel(string mode)
    property real pillWidth: (width - spacing) / 2

    readonly property bool isWifi: Net.isWifi
    readonly property bool isEthernet: Net.connected && !Net.isWifi
    readonly property bool wifiOn: Net.wifiEnabled

    // A switch card: click toggles, right click or the chevron opens the panel.
    component ToggleCard: Rectangle {
        id: card
        property bool on: false
        property string icon
        property string title
        property string status
        property string panelName
        property string chevronName
        signal toggled
        width: root.pillWidth
        height: 52
        radius: Theme.shapeLg
        color: on ? Theme.inverted : area.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.button === Qt.RightButton ? root.requestPanel(card.panelName) : card.toggled()
        }
        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: 17
            color: card.on ? Theme.invertedFg : Theme.surfaceHigh
            Behavior on color { ColorAnimation { duration: Theme.durMedium } }
            Text {
                anchors.centerIn: parent
                text: card.icon
                color: card.on ? Theme.inverted : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }
        }
        Column {
            anchors.left: badge.right
            anchors.right: chevron.left
            anchors.leftMargin: 9
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            Text {
                width: parent.width
                text: card.title
                color: card.on ? Theme.invertedFg : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: card.status
                color: card.on ? Theme.invertedFg : Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
                elide: Text.ElideRight
            }
        }
        DetailChevron {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: card.on ? Theme.invertedFg : Theme.fgDim
            Accessible.name: Cfg.t(card.chevronName)
            onTriggered: root.requestPanel(card.panelName)
        }
    }

    // Lit while it carries traffic or the Wi-Fi radio is on. On a cable it is
    // no Wi-Fi switch, so a click opens the list instead.
    ToggleCard {
        on: root.isEthernet || root.wifiOn
        icon: root.isEthernet ? "lan" : !root.wifiOn ? "wifi_off" : Net.wifiConnecting ? "wifi_find" : "wifi"
        title: root.isEthernet ? Net.connectionName || "Ethernet"
            : root.isWifi ? Net.connectionName || "Wi-Fi"
            : Net.connecting || "Wi-Fi"
        status: root.isEthernet ? Cfg.t("CONNECTED")
            : !root.wifiOn ? Cfg.t("OFF")
            : Net.wifiConnecting ? Cfg.t("Connecting…")
            : root.isWifi ? (Net.signal_ >= 0 ? Net.signal_ + "%" : Cfg.t("CONNECTED"))
            : Cfg.t("NOT CONNECTED")
        panelName: "wifi"
        chevronName: "NETWORK"
        onToggled: root.isEthernet ? root.requestPanel("wifi") : Net.toggleWifi()
    }
    // A connected device shows by name, with its battery when it reports one.
    ToggleCard {
        readonly property var device: Net.btKnown.find(d => d.connected) ?? null
        on: Net.btEnabled
        icon: on ? "bluetooth" : "bluetooth_disabled"
        title: "Bluetooth"
        status: !on ? Cfg.t("OFF") : !device ? Cfg.t("ON")
            : device.battery >= 0 ? device.name + " · " + device.battery + "%" : device.name
        panelName: "bt"
        chevronName: "DEVICES"
        onToggled: Net.toggleBt()
    }

    // Sound: the output's name, the level with mute, and the microphone.
    Rectangle {
        width: root.pillWidth
        height: 52
        radius: Theme.shapeLg
        color: Theme.surfaceAlt
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: root.requestPanel("audio")
        }
        Text {
            id: soundLabel
            x: 12
            y: 8
            text: Cfg.t("SOUND")
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.bodySmall
            font.weight: Font.Medium
            font.letterSpacing: Theme.labelSpacing
        }
        DetailChevron {
            id: soundChevron
            anchors.left: soundLabel.right
            anchors.leftMargin: 1
            anchors.verticalCenter: soundLabel.verticalCenter
            font.pixelSize: 15
            color: Theme.fgDim
            Accessible.name: Cfg.t("SOUND")
            onTriggered: root.requestPanel("audio")
        }
        // Long device names keep their end, where they differ.
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: soundLabel.verticalCenter
            width: parent.width - soundLabel.width - soundChevron.width - 32
            horizontalAlignment: Text.AlignRight
            text: Audio.description
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            elide: Text.ElideLeft
        }
        Text {
            id: speaker
            x: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 9
            text: Audio.muted ? "volume_off" : "volume_up"
            // Red above 100 %.
            color: Audio.muted ? Theme.fgFaint : Audio.boosted ? Theme.alert : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 16
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                Accessible.role: Accessible.Button
                Accessible.name: Audio.muted ? Cfg.t("UNMUTE") : Cfg.t("MUTE")
                onClicked: mouse => mouse.button === Qt.RightButton ? root.requestPanel("audio") : Audio.toggleMute()
            }
        }
        VolumeTrack {
            anchors.left: speaker.right
            anchors.right: microphone.visible ? microphone.left : parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: microphone.visible ? 8 : 12
            anchors.verticalCenter: speaker.verticalCenter
            color: Theme.surfaceHigh
            value: Audio.volume
            maxValue: Audio.maxVolume
            muted: Audio.muted
            accessibleName: Cfg.t("SOUND")
            onMoved: value => Audio.setVolume(value)
        }
        MicToggle {
            id: microphone
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: speaker.verticalCenter
        }
    }
    BrightnessCard {
        width: root.pillWidth
        height: 52
        onRequestDetails: root.requestPanel("brightness")
    }
}
