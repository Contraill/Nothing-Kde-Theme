// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy
import "../devices.js" as Devices

KCM.SimpleKCM {
    id: page
    property int cfg_widgetVariant
    property string cfg_deviceHistory
    property string cfg_deviceKinds
    property string cfg_hiddenDevices
    property string cfg_focusDevice
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome
    property alias cfg_transparent: theme.transparent

    function parse(text, fallback) {
        try { return JSON.parse(text || "") ?? fallback; } catch (e) { return fallback; }
    }
    readonly property var seen: parse(cfg_deviceHistory, [])
    readonly property var kinds: parse(cfg_deviceKinds, {})
    readonly property var hidden: parse(cfg_hiddenDevices, [])
    readonly property bool single: cfg_widgetVariant >= 2
    readonly property var kindNames: [i18n("Phone"), i18n("Tablet"), i18n("Laptop"), i18n("Computer"), i18n("Headphones"), i18n("Earbuds"),
        i18n("Watch"), i18n("Mouse"), i18n("Keyboard"), i18n("Speaker"), i18n("Game controller")]
    function kindOf(device) {
        return Devices.kinds.includes(kinds[device.key]) ? kinds[device.key] : device.kind;
    }

    ColumnLayout {
        spacing: 10
        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: page.cfg_widgetVariant
            onPicked: value => page.cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: [
                {label: i18n("Rings"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")},
                {label: i18n("Circles"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")},
                {label: i18n("Circle"), value: 2, source: Qt.resolvedUrl("../everything/EveryBattery.qml"), props: {round: true, percent: 78, charging: true}},
                {label: i18n("Pill"), value: 3, source: Qt.resolvedUrl("../everything/EveryBattery.qml"), props: {round: false, percent: 78}}
            ]
        }
        QQC2.Label {
            text: page.single ? i18n("Device:") : i18n("Devices:")
            font.weight: Font.Medium
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: page.seen.length === 0
            text: i18n("Devices appear here once they have been connected with a battery reading.")
            wrapMode: Text.Wrap
            opacity: 0.7
        }
        // One row per device seen: shown or chosen, and what kind it is.
        Repeater {
            model: page.seen
            RowLayout {
                id: row
                required property var modelData
                required property int index
                spacing: 8
                QQC2.CheckBox {
                    visible: !page.single
                    checked: !page.hidden.includes(row.modelData.key)
                    onToggled: {
                        const keys = page.hidden.filter(k => k !== row.modelData.key);
                        page.cfg_hiddenDevices = JSON.stringify(checked ? keys : keys.concat([row.modelData.key]));
                        checked = Qt.binding(() => !page.hidden.includes(row.modelData.key));
                    }
                }
                QQC2.RadioButton {
                    visible: page.single
                    checked: page.cfg_focusDevice ? page.cfg_focusDevice === row.modelData.key : row.index === 0
                    onToggled: {
                        page.cfg_focusDevice = row.modelData.key;
                        checked = Qt.binding(() => page.cfg_focusDevice ? page.cfg_focusDevice === row.modelData.key : row.index === 0);
                    }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 120
                    text: row.modelData.key === "computer" ? i18n("This computer") : row.modelData.name
                    elide: Text.ElideRight
                }
                QQC2.ComboBox {
                    model: page.kindNames
                    currentIndex: Math.max(0, Devices.kinds.indexOf(page.kindOf(row.modelData)))
                    onActivated: index => {
                        const next = Object.assign({}, page.kinds);
                        next[row.modelData.key] = Devices.kinds[index];
                        page.cfg_deviceKinds = JSON.stringify(next);
                    }
                }
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Phones and tablets come from KDE Connect, the rest from Bluetooth; clicking a phone opens it in KDE Connect.")
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: 9
        }
        Glassy.ThemeSettings { id: theme; cardOption: true }
    }
}
