import QtQuick
import org.kde.prison as Prison
import "."
Item {
    id: popup
    property string mode: "wifi"
    property bool visible_: true

    signal closed

    implicitHeight: col.implicitHeight + 44

    readonly property bool radioEnabled: mode === "wifi" ? Net.wifiEnabled : Net.btEnabled
    readonly property int listMax: 250
    readonly property var connectedList: mode === "wifi" ? Net.nearbyNets.filter(n => n.connected) : Net.btKnown.filter(d => d.connected)

    readonly property var known: {
        if (mode === "wifi") {
            const puestas = {};
            for (const n of popup.connectedList)
                puestas[n.name] = true;
            return Net.savedNets.filter(n => !puestas[n.name]);
        }
        return Net.btKnown.filter(d => !d.connected);
    }

    readonly property var nearby: {
        if (mode === "wifi") {
            const guardadas = {};
            for (const n of Net.savedNets)
                guardadas[n.name] = true;
            return Net.nearbyNets.filter(n => !n.connected && !guardadas[n.name]);
        }
        return Net.btNearby;
    }
    property string asking: ""
    property string detail: ""
    property bool showPassword: false
    // Keep NetworkManager from reordering rows while a password is typed.
    onAskingChanged: {
        Net.holdNetworkUpdates = asking !== "";
        showPassword = false;
    }

    function toggle(): void {
        if (mode === "wifi")
            Net.toggleWifi();
        else
            Net.toggleBt();
    }
    function btIcon(type): string {
        // BluezQt::Device::Type
        return ({0: "smartphone", 2: "computer", 4: "headset_mic", 5: "headphones", 6: "speaker",
                 7: "keyboard", 8: "mouse", 9: "sports_esports", 10: "tablet", 12: "photo_camera",
                 13: "print", 14: "watch"})[type] ?? "bluetooth";
    }
    Component.onCompleted: {
        Net.wifiCode = "";
        if (popup.mode === "bt")
            Net.scanBt(true);
        else
            Net.refreshLists();
    }
    Component.onDestruction: {
        Net.holdNetworkUpdates = false;
        if (popup.mode === "bt")
            Net.scanBt(false);
    }
    Connections {
        target: Net
        function onBtEnabledChanged() {
            if (popup.mode === "bt" && Net.btEnabled)
                Net.scanBt(true);
        }
        function onWifiEnabledChanged() {
            if (popup.mode === "wifi")
                Net.refreshLists();
        }
    }

    Item {
        id: card
        anchors.fill: parent

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 10
            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: popup.mode === "wifi" ? Cfg.t("NETWORK") : Cfg.t("DEVICES")
                    color: Theme.fgFaint
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.letterSpacing: Theme.labelSpacing
                }

                Row {
                    anchors.right: closeBtn.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    HeaderChip {
                        visible: popup.mode === "wifi" && (Net.hotspotSupported || Net.hotspotActive)
                        icon: "wifi_tethering"
                        label: Cfg.t("HOTSPOT")
                        active: Net.hotspotActive
                        onTriggered: Net.toggleHotspot()
                    }
                    HeaderChip {
                        visible: popup.mode === "wifi" && Net.wifiAvailable
                        icon: "flight"
                        label: Cfg.t("AIRPLANE MODE")
                        active: Net.airplaneMode
                        onTriggered: Net.toggleAirplaneMode()
                    }
                    HeaderChip {
                        icon: "settings"
                        label: popup.mode === "wifi" ? Cfg.t("NETWORK SETTINGS") : Cfg.t("BLUETOOTH SETTINGS")
                        onTriggered: {
                            if (popup.mode === "wifi")
                                Net.openNetworkSettings();
                            else
                                Net.openBluetoothSettings();
                            popup.closed();
                        }
                    }
                }

                Rectangle {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: height / 2
                    color: closeMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durShort
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        color: closeMa.containsMouse ? Theme.fg : Theme.fgDim
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.closed()
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 46
                radius: Theme.shapeLg
                color: popup.radioEnabled ? Theme.inverted : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }

                Text {
                    id: hIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: popup.mode === "wifi" ? (popup.radioEnabled ? "wifi" : "wifi_off") : (popup.radioEnabled ? "bluetooth" : "bluetooth_disabled")
                    color: popup.radioEnabled ? Theme.invertedFg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 20
                }

                Text {
                    anchors.left: hIcon.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: popup.mode === "wifi" ? "WI-FI" : "BLUETOOTH"
                    color: popup.radioEnabled ? Theme.invertedFg : Theme.fg
                    font.letterSpacing: Theme.labelSpacing
                    font.family: Theme.font
                    font.pixelSize: Theme.bodyMedium
                    font.weight: Font.Medium
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 24
                    radius: height / 2
                    color: popup.radioEnabled ? Theme.invertedFg : Theme.surfaceHigh
                    border.width: popup.radioEnabled ? 0 : 2
                    border.color: Theme.outline

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durMedium
                        }
                    }

                    Rectangle {
                        width: popup.radioEnabled ? 18 : 14
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: popup.radioEnabled ? parent.width - width - 3 : 4
                        color: popup.radioEnabled ? Theme.inverted : Theme.fgFaint

                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.durMedium
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Theme.emphasized
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.durShort
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.toggle()
                }
            }
            component HeaderChip: Rectangle {
                id: chip
                property string icon: ""
                property string label: ""
                property bool active: false
                signal triggered

                width: 26
                height: 26
                radius: height / 2
                color: chip.active ? Theme.inverted : chipMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                Accessible.role: Accessible.Button
                Accessible.name: chip.label
                Accessible.checkable: chip.active
                Accessible.onPressAction: chip.triggered()

                Text {
                    anchors.centerIn: parent
                    text: chip.icon
                    color: chip.active ? Theme.invertedFg : chipMa.containsMouse ? Theme.fg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 15
                }
                MouseArea {
                    id: chipMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: chip.triggered()
                }
            }
            component AccionBtn: Rectangle {
                id: ab
                property string etiqueta: ""
                property bool fuerte: false
                property bool peligro: false
                signal apretado

                width: abTxt.implicitWidth + 22
                height: 28
                radius: height / 2

                color: ab.fuerte ? (abMa.containsMouse ? Qt.lighter(Theme.inverted, 1.1) : Theme.inverted) : abMa.containsMouse ? Qt.alpha(ab.peligro ? Theme.alert : Theme.fg, Theme.stateHover) : "transparent"
                border.width: ab.fuerte ? 0 : 1
                border.color: ab.peligro ? Theme.alert : Theme.outline

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    id: abTxt
                    anchors.centerIn: parent
                    text: ab.etiqueta
                    color: ab.fuerte ? Theme.invertedFg : ab.peligro ? Theme.alert : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }

                MouseArea {
                    id: abMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ab.apretado()
                }
            }
            component ConnRow: Rectangle {
                id: cr
                property var item: null
                property bool isKnown: false
                readonly property string ident: popup.mode === "wifi" ? (item?.name ?? "") : (item?.mac ?? "")

                readonly property bool isConnected: item?.connected ?? false
                readonly property bool isBusy: ident !== "" && (Net.connecting === ident || (item?.activating ?? false))
                readonly property bool didFail: ident !== "" && Net.failed === ident
                readonly property bool askingPass: popup.asking !== "" && popup.asking === ident
                readonly property bool abierto: popup.detail !== "" && popup.detail === ident

                readonly property string detalleTexto: {
                    if (popup.mode !== "wifi")
                        return [cr.item?.mac ?? "", (cr.item?.battery ?? -1) >= 0 ? Cfg.t("BATTERY") + " " + cr.item.battery + "%" : ""].filter(Boolean).join(" · ");
                    const partes = [];
                    if (cr.item?.signal !== undefined)
                        partes.push(Cfg.t("Signal") + " " + cr.item.signal + "%");
                    if (cr.item?.secure !== undefined)
                        partes.push(cr.item.secure ? Cfg.t("Secured") : Cfg.t("Open"));
                    return partes.join(" · ");
                }

                function conectar(): void {
                    const it = cr.item;
                    if (!it)
                        return;

                    if (popup.mode === "wifi") {
                        if (cr.isKnown) {
                            Net.connectNet(it.name);
                            return;
                        }
                        // WPA-Enterprise and similar ask through KDE's own credentials dialog.
                        if (it.secure && it.staticPassword) {
                            popup.asking = cr.askingPass ? "" : cr.ident;
                            return;
                        }
                        Net.joinNet(it.name, "");
                        return;
                    }

                    if (cr.isKnown)
                        Net.connectBt(it.mac);
                    else
                        Net.pairBt(it.mac);
                }

                function desconectar(): void {
                    if (!cr.item)
                        return;
                    if (popup.mode === "wifi")
                        Net.disconnectNet(cr.item.name);
                    else
                        Net.disconnectBt(cr.item.mac);
                }

                function olvidar(): void {
                    if (!cr.item)
                        return;
                    if (popup.mode === "wifi")
                        Net.forgetNet(cr.item.name);
                    else
                        Net.forgetBt(cr.item.mac);
                    popup.detail = "";
                }

                width: lista.width
                height: askingPass ? 90 : abierto ? 44 + detalle.implicitHeight + 8 : 44
                radius: Theme.shapeMd
                color: crMa.containsMouse || cr.isBusy || cr.askingPass || cr.abierto ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }

                Item {
                    id: fila
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 44
                    Text {
                        id: crIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !cr.isBusy
                        text: {
                            if (popup.mode === "wifi")
                                return cr.isConnected ? "wifi" : (cr.item?.secure ?? false) ? "lock" : "wifi_find";
                            return popup.btIcon(cr.item?.type ?? -1);
                        }
                        color: cr.didFail ? Theme.alert : cr.isConnected ? Theme.fg : Theme.fgFaint
                        font.family: Theme.fontIcons
                        font.pixelSize: 18
                    }
                    Item {
                        id: spinner
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        visible: cr.isBusy

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.outline
                        }

                        Item {
                            anchors.fill: parent

                            RotationAnimator on rotation {
                                running: spinner.visible
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1100
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 0
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.fg
                            }
                        }
                    }

                    Column {
                        anchors.left: crIcon.right
                        anchors.leftMargin: 10
                        anchors.right: crAction.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            width: parent.width
                            text: cr.item?.name || Cfg.t("Unknown")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.bodySmall
                            font.weight: cr.isConnected ? Font.Medium : Font.Normal
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: {
                                if (cr.isBusy)
                                    return popup.mode === "wifi" || cr.isKnown ? Cfg.t("Connecting…") : Cfg.t("Pairing…");
                                if (cr.askingPass)
                                    return Cfg.t("Enter the password");
                                if (cr.didFail)
                                    return Cfg.t("Couldn't connect");
                                if (cr.isConnected)
                                    return (cr.item?.battery ?? -1) >= 0 ? Cfg.t("Connected") + " · " + cr.item.battery + "%" : Cfg.t("Connected");
                                if (cr.isKnown)
                                    return Cfg.t("Saved");
                                return Cfg.t("Available");
                            }
                            color: cr.didFail ? Theme.alert : Theme.fgVariant
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        id: crAction
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "expand_more"
                        color: cr.abierto || detMa.containsMouse ? Theme.fg : Theme.fgFaint
                        font.family: Theme.fontIcons
                        font.pixelSize: 18

                        rotation: cr.abierto ? 180 : 0

                        Behavior on rotation {
                            NumberAnimation {
                                duration: Theme.durMedium
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Theme.emphasized
                            }
                        }

                        MouseArea {
                            id: detMa
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.detail = cr.abierto ? "" : cr.ident
                        }
                    }

                    MouseArea {
                        id: crMa
                        anchors.fill: parent
                        anchors.rightMargin: 30
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !cr.isBusy
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                popup.detail = cr.abierto ? "" : cr.ident;
                                return;
                            }
                            if (cr.isConnected)
                                cr.desconectar();
                            else
                                cr.conectar();
                        }
                    }
                }
                Column {
                    id: detalle
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: fila.bottom
                    anchors.leftMargin: 40
                    anchors.rightMargin: 10
                    spacing: 8
                    visible: cr.abierto && !cr.askingPass
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durShort
                        }
                    }

                    Text {
                        width: parent.width
                        visible: cr.detalleTexto !== ""
                        text: cr.detalleTexto
                        color: Theme.fgVariant
                        font.family: Theme.font
                        font.pixelSize: Theme.labelSmall
                        elide: Text.ElideRight
                    }

                    Row {
                        spacing: 6

                        AccionBtn {
                            etiqueta: Cfg.t("CONNECT")
                            fuerte: true
                            visible: !cr.isConnected
                            onApretado: cr.conectar()
                        }

                        AccionBtn {
                            etiqueta: Cfg.t("DISCONNECT")
                            fuerte: true
                            visible: cr.isConnected
                            onApretado: cr.desconectar()
                        }

                        AccionBtn {
                            etiqueta: Cfg.t("SHARE")
                            visible: popup.mode === "wifi" && cr.isKnown && (cr.item?.saved ?? false)
                            onApretado: Net.shareNet(cr.item.name)
                        }

                        AccionBtn {
                            etiqueta: Cfg.t("FORGET")
                            peligro: true
                            visible: cr.isKnown
                            onApretado: cr.olvidar()
                        }
                    }
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: fila.bottom
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 2
                    height: 36
                    radius: Theme.shapeSm
                    color: Theme.surfaceAlt
                    visible: cr.askingPass
                    clip: true
                    onVisibleChanged: if (visible) {
                        passIn.text = "";
                        passIn.forceActiveFocus();
                    }

                    TextInput {
                        id: passIn
                        anchors.left: parent.left
                        anchors.right: revealBtn.left
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.bodySmall
                        echoMode: popup.showPassword ? TextInput.Normal : TextInput.Password
                        selectByMouse: true
                        selectionColor: Qt.alpha(Theme.fg, 0.25)
                        clip: true

                        onAccepted: okBtn.entrar()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: passIn.text === ""
                            text: Cfg.t("Password")
                            color: Theme.fgFaint
                            font.family: Theme.font
                            font.pixelSize: Theme.bodySmall
                        }
                    }

                    Rectangle {
                        id: revealBtn
                        anchors.right: okBtn.left
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: height / 2
                        color: revealMa.containsMouse ? Theme.surfaceHigh : "transparent"
                        Accessible.role: Accessible.Button
                        Accessible.name: popup.showPassword ? Cfg.t("HIDE PASSWORD") : Cfg.t("SHOW PASSWORD")

                        Text {
                            anchors.centerIn: parent
                            text: popup.showPassword ? "visibility_off" : "visibility"
                            color: Theme.fgDim
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                        }
                        MouseArea {
                            id: revealMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.showPassword = !popup.showPassword
                        }
                    }

                    Rectangle {
                        id: okBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: height / 2
                        color: okMa.containsMouse ? Theme.inverted : "transparent"

                        function entrar() {
                            if (passIn.text === "")
                                return;
                            Net.joinNet(cr.item.name, passIn.text);
                            popup.asking = "";
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durShort
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            color: okMa.containsMouse ? Theme.invertedFg : Theme.fgDim
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                        }

                        MouseArea {
                            id: okMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: okBtn.entrar()
                        }
                    }
                }
            }

            component SectionLabel: Text {
                color: Theme.outline
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.weight: Font.Medium
                font.letterSpacing: 0.6
            }
            Column {
                width: parent.width
                spacing: 8
                visible: popup.mode === "wifi" && Net.wifiCode !== ""

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
                    color: Theme.fgVariant
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    elide: Text.ElideMiddle
                }
                AccionBtn {
                    anchors.horizontalCenter: parent.horizontalCenter
                    etiqueta: Cfg.t("CLOSE")
                    onApretado: Net.wifiCode = ""
                }
            }

            Item {
                width: parent.width
                height: Math.min(popup.listMax, lista.contentHeight)
                visible: popup.radioEnabled && !(popup.mode === "wifi" && Net.wifiCode !== "")

                Flickable {
                    id: lista
                    anchors.fill: parent
                    contentHeight: dentro.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 3500

                    Column {
                        id: dentro
                        width: lista.width
                        spacing: 10
                        SectionLabel {
                            text: popup.mode === "wifi" ? Cfg.t("CONNECTED") : Cfg.t("CONNECTED")
                            visible: popup.connectedList.length > 0
                        }

                        Column {
                            width: parent.width
                            spacing: 2
                            visible: popup.connectedList.length > 0

                            Repeater {
                                model: popup.connectedList

                                ConnRow {
                                    required property var modelData
                                    item: modelData
                                    isKnown: true
                                }
                            }
                        }
                        SectionLabel {
                            text: popup.mode === "wifi" ? Cfg.t("SAVED NETWORKS") : Cfg.t("KNOWN DEVICES")
                            visible: popup.known.length > 0
                        }

                        Column {
                            width: parent.width
                            spacing: 2
                            visible: popup.known.length > 0

                            Repeater {
                                model: popup.known

                                ConnRow {
                                    required property var modelData
                                    item: modelData
                                    isKnown: true
                                }
                            }
                        }
                        SectionLabel {
                            text: popup.mode === "wifi" ? Cfg.t("NEARBY NETWORKS") : Cfg.t("NEARBY DEVICES")
                        }

                        Column {
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: popup.nearby

                                ConnRow {
                                    required property var modelData
                                    item: modelData
                                    isKnown: false
                                }
                            }

                            Text {
                                width: parent.width
                                visible: popup.nearby.length === 0
                                horizontalAlignment: Text.AlignHCenter
                                topPadding: 8
                                bottomPadding: 8
                                text: (popup.mode === "wifi" ? Net.scanning : Net.btDiscovering) ? Cfg.t("Searching…")
                                    : popup.mode === "wifi" ? Cfg.t("NO OTHER NETWORKS") : Cfg.t("NO NEARBY DEVICES")
                                color: Theme.fgDim
                                font.family: Theme.font
                                font.pixelSize: Theme.bodySmall
                            }
                        }
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    width: 3
                    radius: 1.5
                    color: Theme.fgFaint

                    visible: lista.contentHeight > lista.height
                    height: Math.max(24, lista.height * (lista.height / lista.contentHeight))
                    y: (lista.contentHeight <= lista.height) ? 0 : (lista.contentY / (lista.contentHeight - lista.height)) * (lista.height - height)

                    opacity: lista.moving ? 0.9 : 0.25
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durMedium
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: !popup.radioEnabled
                horizontalAlignment: Text.AlignHCenter
                topPadding: 10
                bottomPadding: 10
                text: popup.mode === "wifi" ? (Net.wifiHardwareEnabled ? Cfg.t("Wi-Fi off") : Cfg.t("WIFI HARDWARE OFF")) : Cfg.t("Bluetooth off")
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
            }
        }
    }
}
