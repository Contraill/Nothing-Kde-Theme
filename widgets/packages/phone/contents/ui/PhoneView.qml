// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.kdeconnect as KDEConnect
import org.kde.plasma.plasma5support as P5Support
import "../../../../shared" as Glassy

// The first paired, reachable KDE Connect device, read the way Plasma's own
// KDE Connect applet does (plugin checkers, then the plugin interfaces).
Item {
    id: root
    property QtObject colors
    property string dotFamily: ""

    KDEConnect.DevicesModel {
        id: devices
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }
    readonly property string deviceId: devices.count > 0 ? String(devices.data(devices.index(0, 0), KDEConnect.DevicesModel.IdModelRole) ?? "") : ""
    readonly property string deviceName: devices.count > 0 ? String(devices.data(devices.index(0, 0), KDEConnect.DevicesModel.NameModelRole) ?? "") : ""
    readonly property KDEConnect.DeviceDbusInterface device: deviceId ? KDEConnect.DeviceDbusInterfaceFactory.create(deviceId) : null

    readonly property KDEConnect.PluginChecker batteryPlugin: KDEConnect.PluginChecker { pluginName: "battery"; device: root.device }
    readonly property KDEConnect.PluginChecker findPlugin: KDEConnect.PluginChecker { pluginName: "findmyphone"; device: root.device }
    // PluginChecker only asks on creation; the device arrives later.
    onDeviceChanged: { batteryPlugin.pluginsChanged(); findPlugin.pluginsChanged(); }
    readonly property KDEConnect.BatteryDbusInterface battery: batteryPlugin.available ? KDEConnect.DeviceBatteryDbusInterfaceFactory.create(deviceId) : null
    readonly property KDEConnect.FindMyPhoneDbusInterface finder: findPlugin.available ? KDEConnect.FindMyPhoneDbusInterfaceFactory.create(deviceId) : null
    readonly property int charge: battery?.charge ?? -1
    readonly property bool charging: battery?.isCharging ?? false

    P5Support.DataSource {
        id: launcher
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)
    }

    component ActionButton: QQC2.AbstractButton {
        id: button
        property string iconName: ""
        implicitWidth: 36
        implicitHeight: 36
        background: Rectangle {
            radius: width / 2
            color: button.hovered ? root.colors.alpha(root.colors.textPrimary, 0.16) : root.colors.alpha(root.colors.textPrimary, 0.08)
        }
        contentItem: Kirigami.Icon {
            source: button.iconName
            isMask: true
            color: root.colors.textPrimary
            implicitWidth: 18
            implicitHeight: 18
        }
    }

    // No phone: say so and offer the pairing settings.
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        visible: !root.device
        spacing: 10
        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            source: "smartphone-symbolic"
            isMask: true
            color: root.colors.textSecondary
            implicitWidth: 34
            implicitHeight: 34
        }
        Text {
            Layout.fillWidth: true
            text: i18n("No phone connected")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: root.colors.textSecondary
        }
        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Pair a phone")
            onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_kdeconnect")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: !!root.device
        spacing: 8
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Glassy.DotRing {
                id: ring
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                count: 36
                value: Math.max(0, root.charge) / 100
                // Low battery takes Nothing's red signal; charging the accent.
                litColor: root.charging ? root.colors.accent : root.charge >= 0 && root.charge <= 15 ? root.colors.error : root.colors.textPrimary
                dimColor: root.colors.divider
            }
            Column {
                anchors.centerIn: ring
                spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.charge >= 0 ? root.charge + "%" : "–"
                    font.family: root.dotFamily
                    font.pixelSize: ring.width * 0.24
                    color: root.colors.textPrimary
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: ring.width * 0.7
                    text: root.charging ? i18n("CHARGING") : root.deviceName
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.pixelSize: 10
                    font.letterSpacing: 1.2
                    color: root.charging ? root.colors.accent : root.colors.textSecondary
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14
            ActionButton {
                visible: !!root.finder
                iconName: "audio-volume-high-symbolic"
                Accessible.name: i18n("Ring the phone")
                onClicked: root.finder.ring()
            }
            ActionButton {
                iconName: "kdeconnect-symbolic"
                Accessible.name: i18n("Open KDE Connect")
                // setsid: the app must not live and die with plasmashell.
                onClicked: launcher.connectSource("setsid -f kdeconnect-app --device " + root.deviceId.replace(/[^A-Za-z0-9_]/g, ""))
            }
        }
    }
}
