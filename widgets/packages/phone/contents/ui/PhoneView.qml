// SPDX-License-Identifier: GPL-3.0-or-later
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.kdeconnect as KDEConnect
import "../../../../shared" as Glassy

// The first paired, reachable KDE Connect device, read the way Plasma's own
// KDE Connect applet does: one delegate per device row, so a phone that drops
// and comes back gets fresh plugin checkers instead of keeping stale ones.
Item {
    id: root
    property QtObject colors
    property string dotFamily: ""

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
        delegate: ColumnLayout {
            id: phone
            required property int index
            required property string deviceId
            required property string name
            readonly property KDEConnect.DeviceDbusInterface device: KDEConnect.DeviceDbusInterfaceFactory.create(deviceId)
            readonly property KDEConnect.PluginChecker batteryPlugin: KDEConnect.PluginChecker { pluginName: "battery"; device: phone.device }
            readonly property KDEConnect.PluginChecker findPlugin: KDEConnect.PluginChecker { pluginName: "findmyphone"; device: phone.device }
            readonly property KDEConnect.BatteryDbusInterface battery: batteryPlugin.available ? KDEConnect.DeviceBatteryDbusInterfaceFactory.create(deviceId) : null
            readonly property KDEConnect.FindMyPhoneDbusInterface finder: findPlugin.available ? KDEConnect.FindMyPhoneDbusInterfaceFactory.create(deviceId) : null
            readonly property int charge: battery?.charge ?? -1
            readonly property bool charging: battery?.isCharging ?? false
            readonly property bool low: charge >= 0 && charge <= 15 && !charging

            anchors.fill: parent
            visible: index === 0
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
                    value: Math.max(0, phone.charge) / 100
                    // Ink; Nothing red only when the phone runs low.
                    litColor: phone.low ? root.colors.accent : root.colors.textPrimary
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
            QQC2.AbstractButton {
                id: ringButton
                Layout.alignment: Qt.AlignHCenter
                visible: !!phone.finder
                implicitWidth: 36
                implicitHeight: 36
                Accessible.name: i18n("Ring the phone")
                QQC2.ToolTip.text: Accessible.name
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                onClicked: phone.finder.ring()
                background: Rectangle {
                    radius: width / 2
                    color: root.colors.alpha(root.colors.textPrimary, ringButton.hovered ? 0.16 : 0.08)
                }
                contentItem: Glassy.DotGlyph {
                    name: "volume"
                    color: root.colors.textPrimary
                    implicitWidth: 18
                    implicitHeight: 18
                }
            }
        }
    }
}
