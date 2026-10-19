// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.prison as Prison
import "."

// Wi-Fi or Bluetooth (by `mode`): the radio switch, then what is connected,
// what is known and what is nearby. A row connects on click and opens its
// details on right click or the chevron; Wi-Fi asks for a password inline
// and can share a saved network as a QR code.
Item {
    id: root

    property string mode: "wifi"
    signal closed
    implicitHeight: content.implicitHeight + 44

    readonly property bool wifi: mode === "wifi"
    readonly property bool radioOn: wifi ? Net.wifiEnabled : Net.btEnabled
    readonly property bool sharing: wifi && Net.wifiCode !== ""

    readonly property var connected: wifi ? Net.nearbyNets.filter(n => n.connected) : Net.btKnown.filter(d => d.connected)
    // Saved networks or paired devices that are not connected now.
    readonly property var known: {
        if (!wifi) return Net.btKnown.filter(d => !d.connected);
        const connectedNames = new Set(connected.map(n => n.name));
        return Net.savedNets.filter(n => !connectedNames.has(n.name));
    }
    readonly property var nearby: {
        if (!wifi) return Net.btNearby;
        const savedNames = new Set(Net.savedNets.map(n => n.name));
        return Net.nearbyNets.filter(n => !n.connected && !savedNames.has(n.name));
    }

    // The row waiting for a password and the row showing its details, by name or address.
    property string asking: ""
    property string expanded: ""
    property bool showPassword: false
    // NetworkManager must not reorder the rows while a password is typed.
    onAskingChanged: {
        Net.holdNetwork = wifi ? asking : "";
        showPassword = false;
    }

    // BluezQt::Device::Type to an icon.
    function deviceIcon(type): string {
        return ({0: "smartphone", 2: "computer", 4: "headset_mic", 5: "headphones", 6: "speaker",
                 7: "keyboard", 8: "mouse", 9: "sports_esports", 10: "tablet", 12: "photo_camera",
                 13: "print", 14: "watch"})[type] ?? "bluetooth";
    }

    // Bluetooth discovery runs only while this panel is open.
    Component.onCompleted: {
        Net.wifiCode = "";
        if (wifi) Net.refreshLists();
        else Net.scanBt(true);
    }
    Component.onDestruction: {
        Net.holdNetwork = "";
        if (!wifi) Net.scanBt(false);
    }
    Connections {
        target: Net
        function onBtEnabledChanged() { if (!root.wifi && Net.btEnabled) Net.scanBt(true); }
        function onWifiEnabledChanged() { if (root.wifi) Net.refreshLists(); }
    }

    component SectionLabel: Text {
        color: Theme.fgFaint
        font.family: Theme.font
        font.pixelSize: Theme.labelSmall
        font.weight: Font.Medium
        font.letterSpacing: 0.6
    }

    component ConnectionRow: Rectangle {
        id: row
        required property var modelData
        property bool isKnown: false
        readonly property var item: modelData
        readonly property string ident: root.wifi ? item?.name ?? "" : item?.mac ?? ""
        readonly property bool isConnected: item?.connected ?? false
        readonly property bool busy: ident !== "" && (Net.connecting === ident || (item?.activating ?? false))
        readonly property bool failed: ident !== "" && Net.failed === ident
        readonly property bool askingPassword: root.asking !== "" && root.asking === ident
        readonly property bool open: root.expanded !== "" && root.expanded === ident
        readonly property string facts: root.wifi
            ? [item?.signal !== undefined ? Cfg.t("Signal") + " " + item.signal + "%" : "",
               item?.secure !== undefined ? (item.secure ? Cfg.t("Secured") : Cfg.t("Open")) : ""].filter(Boolean).join(" · ")
            : [item?.mac ?? "", (item?.battery ?? -1) >= 0 ? Cfg.t("BATTERY") + " " + item.battery + "%" : ""].filter(Boolean).join(" · ")

        function connect(): void {
            if (!item) return;
            if (!root.wifi) {
                if (isKnown) Net.connectBt(item.mac);
                else Net.pairBt(item.mac);
            } else if (isKnown) {
                Net.connectNet(item.name);
            } else if (item.secure && item.staticPassword) {
                // A typed password; WPA-Enterprise and the like ask through KDE's own dialog.
                root.asking = askingPassword ? "" : ident;
            } else {
                Net.joinNet(item.name, "");
            }
        }
        function disconnect(): void {
            if (!item) return;
            if (root.wifi) Net.disconnectNet(item.name);
            else Net.disconnectBt(item.mac);
        }
        function forget(): void {
            if (!item) return;
            if (root.wifi) Net.forgetNet(item.name);
            else Net.forgetBt(item.mac);
            root.expanded = "";
        }
        function sendPassword(): void {
            if (password.text === "") return;
            Net.joinNet(item.name, password.text);
            root.asking = "";
        }

        width: list.width
        height: askingPassword ? 90 : open ? 44 + details.implicitHeight + 8 : 44
        radius: Theme.shapeMd
        color: Qt.alpha(Theme.fg, area.containsMouse || busy || askingPassword || open ? Theme.stateHover : 0)
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Behavior on height { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }

        Item {
            id: line
            width: parent.width
            height: 44
            Text {
                id: icon
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.busy
                text: root.wifi ? (row.isConnected ? "wifi" : (row.item?.secure ?? false) ? "lock" : "wifi_find")
                    : root.deviceIcon(row.item?.type ?? -1)
                color: row.failed ? Theme.alert : row.isConnected ? Theme.fg : Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }
            // While connecting: a dot circling a faint ring.
            Item {
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                visible: row.busy
                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.outline
                }
                Item {
                    anchors.fill: parent
                    RotationAnimator on rotation {
                        running: row.busy
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1100
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.fg
                    }
                }
            }
            Column {
                anchors.left: icon.right
                anchors.right: chevron.left
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    width: parent.width
                    text: row.item?.name || Cfg.t("Unknown")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: row.isConnected ? Font.Medium : Font.Normal
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: row.busy ? (root.wifi || row.isKnown ? Cfg.t("Connecting…") : Cfg.t("Pairing…"))
                        : row.askingPassword ? Cfg.t("Enter the password")
                        : row.failed ? Cfg.t("Couldn't connect")
                        : row.isConnected ? ((row.item?.battery ?? -1) >= 0 ? Cfg.t("Connected") + " · " + row.item.battery + "%" : Cfg.t("Connected"))
                        : row.isKnown ? Cfg.t("Saved")
                        : Cfg.t("Available")
                    color: row.failed ? Theme.alert : Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    elide: Text.ElideRight
                }
            }
            Text {
                id: chevron
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "expand_more"
                color: row.open || chevronArea.containsMouse ? Theme.fg : Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 18
                rotation: row.open ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }
                MouseArea {
                    id: chevronArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = row.open ? "" : row.ident
                }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                anchors.rightMargin: 30
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !row.busy
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) root.expanded = row.open ? "" : row.ident;
                    else if (row.isConnected) row.disconnect();
                    else row.connect();
                }
            }
        }

        // Details: signal and security (or address and battery) and the actions.
        Column {
            id: details
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: line.bottom
            anchors.leftMargin: 40
            anchors.rightMargin: 10
            spacing: 8
            visible: row.open && !row.askingPassword
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
            Text {
                width: parent.width
                visible: row.facts !== ""
                text: row.facts
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                elide: Text.ElideRight
            }
            Row {
                spacing: 6
                TextButton { visible: !row.isConnected; label: Cfg.t("CONNECT"); tone: "strong"; onClicked: row.connect() }
                TextButton { visible: row.isConnected; label: Cfg.t("DISCONNECT"); tone: "strong"; onClicked: row.disconnect() }
                TextButton {
                    visible: root.wifi && row.isKnown && (row.item?.saved ?? false)
                    label: Cfg.t("SHARE")
                    onClicked: Net.shareNet(row.item.name)
                }
                TextButton { visible: row.isKnown; label: Cfg.t("FORGET"); tone: "danger"; onClicked: row.forget() }
            }
        }

        // The password field, with show/hide and join.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: line.bottom
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 2
            height: 36
            radius: Theme.shapeSm
            color: Theme.surfaceAlt
            visible: row.askingPassword
            clip: true
            onVisibleChanged: if (visible) {
                password.text = "";
                password.forceActiveFocus();
            }
            TextInput {
                id: password
                anchors.left: parent.left
                anchors.right: reveal.left
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                selectByMouse: true
                selectionColor: Qt.alpha(Theme.fg, 0.25)
                clip: true
                onAccepted: row.sendPassword()
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: password.text === ""
                    text: Cfg.t("Password")
                    color: Theme.fgFaint
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                }
            }
            RoundButton {
                id: reveal
                anchors.right: join.left
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                height: 28
                flat: true
                color: revealHover.hovered ? Theme.surfaceHigh : "transparent"
                icon: root.showPassword ? "visibility_off" : "visibility"
                iconSize: 16
                Accessible.name: root.showPassword ? Cfg.t("HIDE PASSWORD") : Cfg.t("SHOW PASSWORD")
                onClicked: root.showPassword = !root.showPassword
                HoverHandler { id: revealHover }
            }
            RoundButton {
                id: join
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                height: 28
                on: joinHover.hovered
                color: on ? Theme.inverted : "transparent"
                icon: "arrow_forward"
                iconSize: 16
                onClicked: row.sendPassword()
                HoverHandler { id: joinHover }
            }
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        PanelHeader {
            title: root.wifi ? Cfg.t("NETWORK") : Cfg.t("DEVICES")
            onClosed: root.closed()
            RoundButton {
                visible: root.wifi && (Net.hotspotSupported || Net.hotspotActive)
                icon: "wifi_tethering"
                on: Net.hotspotActive
                Accessible.name: Cfg.t("HOTSPOT")
                onClicked: Net.toggleHotspot()
            }
            RoundButton {
                visible: root.wifi && Net.wifiAvailable
                icon: "flight"
                on: Net.airplaneMode
                Accessible.name: Cfg.t("AIRPLANE MODE")
                onClicked: Net.toggleAirplaneMode()
            }
            RoundButton {
                icon: "settings"
                Accessible.name: root.wifi ? Cfg.t("NETWORK SETTINGS") : Cfg.t("BLUETOOTH SETTINGS")
                onClicked: {
                    if (root.wifi) Net.openNetworkSettings();
                    else Net.openBluetoothSettings();
                    root.closed();
                }
            }
        }

        // The radio itself.
        Rectangle {
            width: parent.width
            height: 46
            radius: Theme.shapeLg
            color: root.radioOn ? Theme.inverted : Theme.surfaceAlt
            Behavior on color { ColorAnimation { duration: Theme.durMedium } }
            Text {
                id: radioIcon
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.wifi ? (root.radioOn ? "wifi" : "wifi_off") : (root.radioOn ? "bluetooth" : "bluetooth_disabled")
                color: root.radioOn ? Theme.invertedFg : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 20
            }
            Text {
                anchors.left: radioIcon.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.wifi ? "WI-FI" : "BLUETOOTH"
                color: root.radioOn ? Theme.invertedFg : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodyMedium
                font.weight: Font.Medium
                font.letterSpacing: Theme.labelSpacing
            }
            ToggleSwitch {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                on: root.radioOn
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wifi ? Net.toggleWifi() : Net.toggleBt()
            }
        }

        // A saved network shared as a QR code, in place of the list.
        Column {
            width: parent.width
            spacing: 8
            visible: root.sharing
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 196
                height: 196
                radius: Theme.shapeMd
                color: "#ffffff"
                Prison.Barcode {
                    anchors.fill: parent
                    anchors.margins: 12
                    barcodeType: Prison.Barcode.QRCode
                    content: Net.wifiCode
                    foregroundColor: "#000000"
                    backgroundColor: "#ffffff"
                }
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Cfg.t("SCAN TO JOIN") + " · " + Net.wifiCodeSsid
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                elide: Text.ElideMiddle
            }
            TextButton {
                anchors.horizontalCenter: parent.horizontalCenter
                label: Cfg.t("CLOSE")
                onClicked: Net.wifiCode = ""
            }
        }

        Item {
            width: parent.width
            height: Math.min(250, list.contentHeight)
            visible: root.radioOn && !root.sharing
            Flickable {
                id: list
                anchors.fill: parent
                contentHeight: sections.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 3500
                Column {
                    id: sections
                    width: list.width
                    spacing: 10
                    SectionLabel {
                        visible: root.connected.length > 0
                        text: Cfg.t("CONNECTED")
                    }
                    Column {
                        width: parent.width
                        spacing: 2
                        visible: root.connected.length > 0
                        Repeater {
                            model: root.connected
                            ConnectionRow { isKnown: true }
                        }
                    }
                    SectionLabel {
                        visible: root.known.length > 0
                        text: root.wifi ? Cfg.t("SAVED NETWORKS") : Cfg.t("KNOWN DEVICES")
                    }
                    Column {
                        width: parent.width
                        spacing: 2
                        visible: root.known.length > 0
                        Repeater {
                            model: root.known
                            ConnectionRow { isKnown: true }
                        }
                    }
                    SectionLabel {
                        text: root.wifi ? Cfg.t("NEARBY NETWORKS") : Cfg.t("NEARBY DEVICES")
                    }
                    Column {
                        width: parent.width
                        spacing: 2
                        Repeater {
                            model: root.nearby
                            ConnectionRow {}
                        }
                        Text {
                            width: parent.width
                            visible: root.nearby.length === 0
                            horizontalAlignment: Text.AlignHCenter
                            topPadding: 8
                            bottomPadding: 8
                            text: (root.wifi ? Net.scanning : Net.btDiscovering) ? Cfg.t("Searching…")
                                : root.wifi ? Cfg.t("NO OTHER NETWORKS") : Cfg.t("NO NEARBY DEVICES")
                            color: Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: Theme.bodySmall
                        }
                    }
                }
            }
            ScrollHint { flickable: list }
        }

        Text {
            width: parent.width
            visible: !root.radioOn
            horizontalAlignment: Text.AlignHCenter
            topPadding: 10
            bottomPadding: 10
            text: root.wifi ? (Net.wifiHardwareEnabled ? Cfg.t("Wi-Fi off") : Cfg.t("WIFI HARDWARE OFF")) : Cfg.t("Bluetooth off")
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.bodySmall
        }
    }
}
