pragma ComponentBehavior: Bound
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kdeconnect as KDEConnect
import "."

// The first reachable KDE Connect device's battery, the way Plasma's own
// KDE Connect applet reads it (battery plugin through PluginChecker).
Row {
    id: root
    spacing: 8

    KDEConnect.DevicesModel {
        id: devices
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }
    Repeater {
        model: Backend.preview ? 0 : devices
        Item {
            id: phone
            required property int index
            required property var model
            readonly property KDEConnect.DeviceDbusInterface device: KDEConnect.DeviceDbusInterfaceFactory.create(model.deviceId)
            readonly property KDEConnect.PluginChecker checker: KDEConnect.PluginChecker {
                pluginName: "battery"
                device: phone.device
            }
            property KDEConnect.BatteryDbusInterface battery: null
            readonly property int charge: battery?.charge ?? -1
            readonly property bool charging: battery?.isCharging ?? false
            Connections {
                target: phone.checker
                function onAvailableChanged() {
                    phone.battery = phone.checker.available ? KDEConnect.DeviceBatteryDbusInterfaceFactory.create(phone.device.id()) : null;
                }
            }
            Component.onCompleted: if (checker.available) battery = KDEConnect.DeviceBatteryDbusInterfaceFactory.create(device.id())

            visible: index === 0 && charge >= 0
            implicitWidth: phoneRow.implicitWidth
            implicitHeight: 24
            Row {
                id: phoneRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: phone.charging ? "mobile_charge" : "smartphone"
                    color: phone.charge <= 15 && !phone.charging ? Theme.alert : Theme.fg
                    font.family: Theme.fontIcons
                    font.pixelSize: 16
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: phone.charge + "%"
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.labelMedium
                }
            }
            PlasmaCore.ToolTipArea {
                anchors.fill: parent
                // Opens KDE Connect on this phone's page.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: (phone.device.name || "KDE Connect") + " · " + phone.charge + "%"
                    // setsid: the app must outlive a shell restart.
                    onClicked: Exec.run("setsid -f kdeconnect-app --device " + phone.device.id().replace(/[^A-Za-z0-9_]/g, ""))
                }
                mainText: phone.device.name || "KDE Connect"
                subText: phone.charge + "%" + (phone.charging ? " · " + Cfg.t("CHARGING") : "")
                location: PlasmaCore.Types.TopEdge
            }
        }
    }
}
