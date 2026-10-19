// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.bluezqt as BluezQt
import "../../../../shared" as Glassy
import "components"
import "everything"
import "devices.js" as Devices

// Batteries: this computer's, phones and tablets paired with KDE Connect, and
// connected Bluetooth devices. Each is drawn as a dot ring, as a filled circle
// with its picture, or one of them alone as the adapted circle or pill. The
// settings say which devices show and what kind each one is.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
        monochrome: Plasmoid.configuration.monochrome
    }
    Glassy.DotFont { id: dotFont }

    // 0 rings, 1 circles, 2 the adapted circle, 3 its pill.
    readonly property int variant: Plasmoid.configuration.widgetVariant
    readonly property bool single: variant >= 2

    function parse(text, fallback) {
        try { return JSON.parse(text || "") ?? fallback; } catch (e) { return fallback; }
    }
    readonly property var kinds: parse(Plasmoid.configuration.deviceKinds, {})
    readonly property var hidden: parse(Plasmoid.configuration.hiddenDevices, [])

    // This computer.
    P5Support.DataSource {
        id: power
        engine: "powermanagement"
        connectedSources: ["Battery"]
    }
    readonly property var computer: {
        const battery = power.data["Battery"] ?? {};
        // A desktop reports no battery, or 0 % while "charging".
        if (!battery["Has Battery"] || (battery["Percent"] === 0 && battery["State"] === "Charging")) return null;
        return {key: "computer", name: i18n("This computer"), charge: battery["Percent"] ?? 0, charging: battery["State"] === "Charging", kind: "laptop"};
    }

    // Connected Bluetooth devices that report a battery.
    readonly property BluezQt.Manager bluetooth: BluezQt.Manager
    property var bluetoothDevices: []
    function readBluetooth() {
        const list = [];
        if (bluetooth.operational) {
            for (let i = 0; i < bluetooth.devices.length; ++i) {
                const device = bluetooth.devices[i];
                if (!device.connected || !device.battery) continue;
                const name = device.name || device.alias || i18n("Bluetooth device");
                list.push({key: "bt:" + device.address, name: name, charge: device.battery.percentage, charging: false,
                           kind: Devices.guess(device.icon + " " + name, "headphones")});
            }
        }
        bluetoothDevices = list;
    }
    Connections {
        target: root.bluetooth
        function onDeviceAdded() { root.readBluetooth() }
        function onDeviceRemoved() { root.readBluetooth() }
        function onDeviceChanged() { root.readBluetooth() }
        function onOperationalChanged() { root.readBluetooth() }
    }
    // Battery levels change without a device signal.
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.readBluetooth()
    }

    // KDE Connect is optional: without it the loader fails and lists nothing.
    Loader {
        id: kdeConnect
        source: "KdeConnectSource.qml"
    }

    // Every device with a battery, each with the kind the settings chose; a
    // phone seen through KDE Connect is not listed again from Bluetooth.
    readonly property var available: {
        const phones = kdeConnect.item?.devices ?? [];
        const names = phones.map(d => d.name);
        const all = (computer ? [computer] : []).concat(phones, bluetoothDevices.filter(d => !names.includes(d.name)));
        return all.map(d => Object.assign({}, d, {kind: Devices.kinds.includes(kinds[d.key]) ? kinds[d.key] : d.kind}));
    }
    readonly property var shown: {
        if (single) {
            const focus = available.find(d => d.key === Plasmoid.configuration.focusDevice);
            return focus ? [focus] : available.slice(0, 1);
        }
        return available.filter(d => !hidden.includes(d.key));
    }

    // Remember devices once seen, so the settings can name them while they are away.
    onAvailableChanged: {
        const seen = parse(Plasmoid.configuration.deviceHistory, []);
        let changed = false;
        for (const d of available) {
            const known = seen.find(s => s.key === d.key);
            if (!known) { seen.push({key: d.key, name: d.name, kind: d.kind}); changed = true; }
            else if (known.name !== d.name) { known.name = d.name; changed = true; }
        }
        if (changed) Plasmoid.configuration.deviceHistory = JSON.stringify(seen);
    }

    function open(device) {
        if (device.key.startsWith("kdc:")) kdeConnect.item?.open(device.key);
    }

    // Rings in a row, four as a square, more in rows of three.
    readonly property int columns: shown.length <= 3 ? Math.max(1, shown.length) : shown.length === 4 ? 2 : 3
    readonly property int rows: Math.ceil(Math.max(1, shown.length) / columns)

    fullRepresentation: Item {
        Layout.preferredWidth: root.single ? 200 : root.columns === 1 ? 220 : root.columns * 110 + 20
        Layout.preferredHeight: root.variant === 3 ? 110 : root.single ? 200 : root.rows * (root.columns === 1 ? 200 : 125) + 20
        Layout.minimumWidth: 150
        Layout.minimumHeight: root.variant === 3 ? 80 : 150

        EveryBattery {
            anchors.fill: parent
            visible: root.single && root.shown.length > 0
            colors: nColors
            family: dotFont.name
            transparent: Plasmoid.configuration.transparent
            round: root.variant === 2
            percent: root.shown[0]?.charge ?? 0
            charging: root.shown[0]?.charging ?? false
            glyph: root.shown[0] && root.shown[0].key !== "computer" ? Devices.glyph(root.shown[0].kind) : "bolt-dots"
            MouseArea {
                anchors.fill: parent
                enabled: (root.shown[0]?.key ?? "").startsWith("kdc:")
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.open(root.shown[0])
            }
        }

        Glassy.GlassySurface {
            id: card
            visible: !root.single || root.shown.length === 0
            bare: Plasmoid.configuration.transparent
            anchors.fill: parent
            anchors.margins: 10
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }

        // Nothing to show yet.
        Column {
            anchors.centerIn: card
            width: card.width - 28
            visible: root.shown.length === 0
            spacing: 8
            Glassy.DotGlyph {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 36
                height: 28
                name: "bolt"
                color: nColors.accent
            }
            Text {
                width: parent.width
                text: root.available.length ? i18n("No device is chosen in the settings") : i18n("No device with a battery is connected")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                font.pixelSize: 12
                color: nColors.textSecondary
            }
        }

        GridLayout {
            anchors.fill: card
            anchors.margins: 14
            visible: !root.single
            columns: root.columns
            columnSpacing: 12
            rowSpacing: 10
            Repeater {
                model: root.single ? [] : root.shown
                Item {
                    id: cell
                    required property var modelData
                    readonly property bool low: modelData.charge <= 15 && !modelData.charging
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    MouseArea {
                        anchors.fill: parent
                        enabled: cell.modelData.key.startsWith("kdc:")
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.open(cell.modelData)
                    }

                    // 0: a dot ring with the charge, the device's picture and its name.
                    Item {
                        anchors.fill: parent
                        visible: root.variant === 0
                        readonly property real size: Math.min(width, height - caption.height - 4)
                        Glassy.DotRing {
                            id: ring
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.size
                            height: width
                            count: root.shown.length === 1 ? 36 : 24
                            value: cell.modelData.charge / 100
                            litColor: cell.low ? nColors.error : nColors.accent
                            dimColor: nColors.divider
                        }
                        Column {
                            anchors.centerIn: ring
                            spacing: ring.width * 0.03
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cell.modelData.charge + "%"
                                font.family: dotFont.name
                                font.pixelSize: ring.width * 0.22
                                color: nColors.textPrimary
                            }
                            Glassy.DotGlyph {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: ring.width * 0.2
                                height: width * 7 / 9
                                name: cell.modelData.charging ? "bolt" : Devices.glyph(cell.modelData.kind)
                                color: nColors.accent
                            }
                        }
                        Text {
                            id: caption
                            anchors.top: ring.bottom
                            anchors.topMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            text: cell.modelData.charging ? i18n("CHARGING") : cell.modelData.name
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: 10
                            font.letterSpacing: 1.2
                            color: cell.modelData.charging ? nColors.accent : nColors.textSecondary
                        }
                    }

                    // 1: the filled circle with the device's picture.
                    CircularBatteryProgress {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        visible: root.variant === 1
                        colors: nColors
                        percentage: cell.modelData.charge
                        isCharging: cell.modelData.charging
                        isSystemDevice: cell.modelData.key === "computer"
                        deviceIcon: Devices.picture(cell.modelData.kind)
                    }
                }
            }
        }
    }
}
