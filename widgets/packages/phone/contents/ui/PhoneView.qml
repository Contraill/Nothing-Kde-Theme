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
// KDE Connect applet does: one delegate per device row, so a phone that drops
// and comes back gets fresh plugin checkers instead of keeping stale ones.
Item {
    id: root
    property QtObject colors
    property string dotFamily: ""

    P5Support.DataSource {
        id: launcher
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)
    }

    KDEConnect.DevicesModel {
        id: devices
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }

    // No phone: say so and offer the pairing settings.
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width
        visible: phones.count === 0
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

    Repeater {
        id: phones
        model: devices
        delegate: Item {
            id: phone
            required property int index
            required property string deviceId
            required property string name
            readonly property KDEConnect.DeviceDbusInterface device: KDEConnect.DeviceDbusInterfaceFactory.create(deviceId)
            readonly property KDEConnect.PluginChecker batteryPlugin: KDEConnect.PluginChecker { pluginName: "battery"; device: phone.device }
            readonly property KDEConnect.BatteryDbusInterface battery: batteryPlugin.available ? KDEConnect.DeviceBatteryDbusInterfaceFactory.create(deviceId) : null
            readonly property int charge: battery?.charge ?? -1
            readonly property bool charging: battery?.isCharging ?? false
            readonly property bool low: charge >= 0 && charge <= 15 && !charging

            anchors.fill: parent
            visible: index === 0
            // A click opens the phone in KDE Connect; setsid keeps the app
            // from living and dying with plasmashell.
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: i18n("Open in KDE Connect")
                onClicked: launcher.connectSource("setsid -f kdeconnect-app --device " + phone.deviceId.replace(/[^A-Za-z0-9_]/g, ""))
            }
            Item {
                anchors.fill: parent
                Glassy.DotRing {
                    id: ring
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    count: 36
                    value: Math.max(0, phone.charge) / 100
                    litColor: phone.low ? root.colors.error : root.colors.accent
                    dimColor: root.colors.divider
                }
                Column {
                    anchors.centerIn: ring
                    spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: phone.charge >= 0 ? phone.charge + "%" : "–"
                        font.family: root.dotFamily
                        font.pixelSize: ring.width * 0.24
                        color: root.colors.textPrimary
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: ring.width * 0.7
                        text: phone.charging ? i18n("CHARGING") : phone.name
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                        color: phone.charging ? root.colors.accent : root.colors.textSecondary
                    }
                }
            }
        }
    }
}
