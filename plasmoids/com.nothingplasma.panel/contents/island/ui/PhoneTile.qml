pragma ComponentBehavior: Bound
import QtQuick
import org.kde.kcmutils as KCMUtils
import org.kde.kdeconnect as KDEConnect
import "."

// Rings the first reachable KDE Connect phone; without one it opens the
// KDE Connect settings to pair. Loaded through a Loader: KDE Connect is optional.
QuickTile {
    id: root

    KDEConnect.DevicesModel {
        id: devices
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }
    readonly property string deviceId: devices.count > 0 ? String(devices.data(devices.index(0, 0), KDEConnect.DevicesModel.IdModelRole) ?? "") : ""
    readonly property string deviceName: devices.count > 0 ? String(devices.data(devices.index(0, 0), KDEConnect.DevicesModel.NameModelRole) ?? "") : ""
    readonly property KDEConnect.DeviceDbusInterface device: deviceId ? KDEConnect.DeviceDbusInterfaceFactory.create(deviceId) : null
    readonly property KDEConnect.PluginChecker checker: KDEConnect.PluginChecker {
        pluginName: "findmyphone"
        device: root.device
    }
    // PluginChecker only asks on creation; the device arrives later.
    onDeviceChanged: checker.pluginsChanged()
    readonly property KDEConnect.FindMyPhoneDbusInterface finder: checker.available ? KDEConnect.FindMyPhoneDbusInterfaceFactory.create(deviceId) : null

    // Briefly filled after ringing, like a pressed quick setting.
    on: ringing.running
    glyph: finder ? "ring_volume" : "smartphone"
    label: finder ? Cfg.t("FIND PHONE") : Cfg.t("CONNECT PHONE")
    stateText: deviceName
    onClicked: {
        if (Backend.preview) return;
        if (finder) {
            finder.ring();
            ringing.restart();
        } else {
            KCMUtils.KCMLauncher.openSystemSettings("kcm_kdeconnect");
            Backend.dismissRequested();
        }
    }
    Timer { id: ringing; interval: 2000 }
}
