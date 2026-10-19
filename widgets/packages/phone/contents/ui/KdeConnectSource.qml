// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import org.kde.kdeconnect as KDEConnect
import org.kde.plasma.plasma5support as P5Support
import "devices.js" as Devices

// The paired, reachable KDE Connect devices with a battery, read the way
// Plasma's own KDE Connect applet does: one delegate per device row, so a
// phone that drops and comes back gets fresh plugin checkers. KDE Connect is
// optional; main.qml loads this on demand.
Item {
    id: source
    // [{key, name, charge, charging, kind}]
    property var devices: []

    function rebuild() {
        const list = [];
        for (let i = 0; i < rows.count; ++i) {
            const row = rows.objectAt(i);
            if (row && row.charge >= 0)
                list.push({key: "kdc:" + row.deviceId, name: row.name, charge: row.charge, charging: row.charging, kind: Devices.guess(row.device?.type, "phone")});
        }
        devices = list;
    }

    // Opens a device in KDE Connect; setsid keeps the app from living and
    // dying with plasmashell.
    function open(key) {
        const id = String(key).replace(/^kdc:/, "").replace(/[^A-Za-z0-9_]/g, "");
        if (id) launcher.connectSource("setsid -f kdeconnect-app --device " + id);
    }
    P5Support.DataSource {
        id: launcher
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)
    }

    KDEConnect.DevicesModel {
        id: model
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }
    Instantiator {
        id: rows
        model: model
        onObjectAdded: source.rebuild()
        onObjectRemoved: source.rebuild()
        delegate: QtObject {
            id: row
            required property string deviceId
            required property string name
            readonly property KDEConnect.DeviceDbusInterface device: KDEConnect.DeviceDbusInterfaceFactory.create(deviceId)
            readonly property KDEConnect.PluginChecker batteryPlugin: KDEConnect.PluginChecker { pluginName: "battery"; device: row.device }
            readonly property KDEConnect.BatteryDbusInterface battery: batteryPlugin.available ? KDEConnect.DeviceBatteryDbusInterfaceFactory.create(deviceId) : null
            readonly property int charge: battery?.charge ?? -1
            readonly property bool charging: battery?.isCharging ?? false
            onChargeChanged: source.rebuild()
            onChargingChanged: source.rebuild()
        }
    }
}
