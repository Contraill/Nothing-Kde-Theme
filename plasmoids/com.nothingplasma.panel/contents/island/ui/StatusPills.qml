import QtQuick
import "."
Grid {
    id: root
    spacing: 8
    columns: 2

    property real pillWidth: (width - spacing) / 2
    signal requestPanel(string mode)
    readonly property bool device: Net.connected
    readonly property bool isWifi: Net.isWifi
    readonly property bool isEthernet: Net.connected && !Net.isWifi
    readonly property bool wifiOn: Net.wifiEnabled
    // The card is "on" when it carries traffic or its radio is enabled.
    readonly property bool netActive: isEthernet || wifiOn

    Rectangle {
        id: netPill
        width: root.pillWidth
        height: 52
        radius: Theme.shapeLg
        color: root.netActive ? Theme.inverted : netMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation {
                duration: Theme.durMedium
            }
        }

        MouseArea {
            id: netMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                // On Ethernet the card is not a Wi-Fi switch; open the list instead.
                if (mouse.button === Qt.RightButton || root.isEthernet)
                    root.requestPanel("wifi");
                else
                    Net.toggleWifi();
            }
        }

        Rectangle {
            id: netIconBg
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: height / 2
            color: root.netActive ? Theme.invertedFg : Theme.surfaceHigh

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durMedium
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.isEthernet ? "lan" : !root.wifiOn ? "wifi_off" : Net.wifiConnecting ? "wifi_find" : "wifi"
                color: root.netActive ? Theme.inverted : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }
        }

        Column {
            anchors.left: netIconBg.right
            anchors.leftMargin: 9
            anchors.right: netChevron.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                text: {
                    if (root.isEthernet)
                        return Net.connectionName || "Ethernet";
                    if (root.isWifi)
                        return Net.connectionName || "Wi-Fi";
                    if (Net.connecting)
                        return Net.connecting;
                    return "Wi-Fi";
                }
                color: root.netActive ? Theme.invertedFg : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (root.isEthernet)
                        return Cfg.t("CONNECTED");
                    if (!root.wifiOn)
                        return Cfg.t("OFF");
                    if (Net.wifiConnecting)
                        return Cfg.t("Connecting…");
                    if (root.isWifi)
                        return Net.signal_ >= 0 ? Net.signal_ + "%" : Cfg.t("CONNECTED");
                    return Cfg.t("NOT CONNECTED");
                }
                color: root.netActive ? Theme.invertedFg : Theme.fgDim
                font.letterSpacing: Theme.labelSpacing
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                elide: Text.ElideRight
            }
        }
        DetailChevron {
            id: netChevron
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: root.netActive ? Theme.invertedFg : Theme.fgDim
            Accessible.name: Cfg.t("NETWORK")
            onTriggered: root.requestPanel("wifi")
        }
    }
    Rectangle {
        id: btPill
        readonly property bool on: Net.btEnabled
        readonly property var connectedDevice: {
            const devs = Net.btKnown;
            for (var i = 0; i < devs.length; i++)
                if (devs[i].connected)
                    return devs[i];
            return null;
        }

        width: root.pillWidth
        height: 52
        radius: Theme.shapeLg
        color: on ? Theme.inverted : btMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation {
                duration: Theme.durMedium
            }
        }

        Rectangle {
            id: btIconBg
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: height / 2
            color: btPill.on ? Theme.invertedFg : Theme.surfaceHigh

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durMedium
                }
            }

            Text {
                anchors.centerIn: parent
                text: btPill.on ? "bluetooth" : "bluetooth_disabled"
                color: btPill.on ? Theme.inverted : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }
        }

        Column {
            anchors.left: btIconBg.right
            anchors.leftMargin: 9
            anchors.right: btChevron.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                text: "Bluetooth"
                color: btPill.on ? Theme.invertedFg : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!btPill.on)
                        return Cfg.t("OFF");
                    const device = btPill.connectedDevice;
                    if (!device)
                        return Cfg.t("ON");
                    return device.battery >= 0 ? device.name + " · " + device.battery + "%" : device.name;
                }
                color: btPill.on ? Theme.invertedFg : Theme.fgDim
                font.letterSpacing: Theme.labelSpacing
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: btMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.requestPanel("bt");
                    return;
                }
                Net.toggleBt();
            }
        }
        DetailChevron {
            id: btChevron
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: btPill.on ? Theme.invertedFg : Theme.fgDim
            Accessible.name: Cfg.t("DEVICES")
            onTriggered: root.requestPanel("bt")
        }
    }
    Rectangle {
        width: root.pillWidth
        height: 52
        radius: Theme.shapeLg
        color: Theme.containerHigh
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: root.requestPanel("audio")
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
        Text {
            id: soundLabel
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.top: parent.top
            anchors.topMargin: 8
            text: Cfg.t("SOUND")
            color: Theme.fg
            font.letterSpacing: Theme.labelSpacing
            font.family: Theme.font
            font.pixelSize: Theme.bodySmall
            font.weight: Font.Medium
        }

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
            id: volIcon
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 9
            text: Audio.muted ? "volume_off" : "volume_up"
            color: Audio.muted ? Theme.fgFaint : Audio.boosted ? Theme.alert : Theme.fgVariant
            font.family: Theme.fontIcons
            font.pixelSize: 16

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                Accessible.role: Accessible.Button
                Accessible.name: Audio.muted ? Cfg.t("UNMUTE") : Cfg.t("MUTE")
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.requestPanel("audio");
                        return;
                    }
                    Audio.toggleMute();
                }
            }
        }
        VolumeTrack {
            anchors.left: volIcon.right
            anchors.leftMargin: 8
            anchors.right: micToggle.visible ? micToggle.left : parent.right
            anchors.rightMargin: micToggle.visible ? 8 : 12
            anchors.verticalCenter: volIcon.verticalCenter
            color: Theme.containerHighest
            value: Audio.volume
            maxValue: Audio.maxVolume
            muted: Audio.muted
            accessibleName: Cfg.t("SOUND")
            onMoved: value => Audio.setVolume(value)
        }
        MicToggle {
            id: micToggle
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: volIcon.verticalCenter
        }
    }
    BrightnessCard {
        width: root.pillWidth
        height: 52
        onRequestDetails: root.requestPanel("brightness")
    }
}
