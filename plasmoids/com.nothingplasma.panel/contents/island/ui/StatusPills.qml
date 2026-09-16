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
    Rectangle {
        id: netPill
        width: root.pillWidth
        height: 52
        radius: Theme.shapeLg
        color: root.device ? Theme.inverted : netMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

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
                if (mouse.button === Qt.RightButton)
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
            color: root.device ? Theme.invertedFg : Theme.surfaceHigh

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durMedium
                }
            }

            Text {
                anchors.centerIn: parent
                text: !root.device ? "wifi_off" : root.isEthernet ? "lan" : "wifi"
                color: root.device ? Theme.inverted : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }
        }

        Column {
            anchors.left: netIconBg.right
            anchors.leftMargin: 9
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                width: parent.width
                text: {
                    if (!root.device)
                        return Cfg.t("No network");
                    if (root.isEthernet)
                        return "Ethernet";
                    return Net.connectionName || "Wi-Fi";
                }
                color: root.device ? Theme.invertedFg : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!root.device)
                        return Cfg.t("NO NETWORK");
                    if (root.isEthernet)
                        return Cfg.t("CONNECTED");
                    return Net.signal_ + "%";
                }
                color: root.device ? Theme.invertedFg : Theme.fgDim
                font.letterSpacing: Theme.labelSpacing
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                elide: Text.ElideRight
            }
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
            anchors.right: parent.right
            anchors.rightMargin: 8
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
                    return btPill.connectedDevice?.name ?? Cfg.t("ON");
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
            width: parent.width - soundLabel.width - 32
            horizontalAlignment: Text.AlignRight
            text: Audio.description
            color: Theme.outline
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
            color: Audio.muted ? Theme.outline : Audio.boosted ? Theme.alert : Theme.fgVariant
            font.family: Theme.fontIcons
            font.pixelSize: 16

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.requestPanel("audio");
                        return;
                    }
                    Audio.toggleMute();
                }
            }
        }
        Rectangle {
            id: volTrack
            readonly property real maxVolume: Audio.maxVolume
            anchors.left: volIcon.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: volIcon.verticalCenter
            height: 6
            radius: 3
            color: Theme.containerHighest

            Rectangle {
                width: volTrack.width * (Audio.muted ? 0 : Math.min(Audio.volume, 1) / volTrack.maxVolume)
                height: parent.height
                radius: parent.radius
                color: Theme.fg

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durShort
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                width: volTrack.width * (Audio.muted ? 0 : Math.max(Audio.volume - 1, 0) / volTrack.maxVolume)
                height: parent.height
                radius: parent.radius
                color: Theme.alert

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durShort
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                function apply(mx) {
                    Audio.setVolume((mx / volTrack.width) * volTrack.maxVolume);
                }

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        root.requestPanel("audio");
                }
                onPressed: mouse => {
                    if (mouse.button !== Qt.LeftButton)
                        return;
                    Audio.holding = true;
                    apply(mouse.x);
                }
                onReleased: Audio.holding = false
                onPositionChanged: mouse => {
                    if (pressed)
                        apply(mouse.x);
                }
            }
        }
    }
    BrightnessCard {
        width: root.pillWidth
        height: 52
        onRequestKeyboard: root.requestPanel("keyboard")
    }
}
