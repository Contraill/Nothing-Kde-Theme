// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property int cfg_widgetVariant
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome

    ColumnLayout {
        spacing: 10
        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: cfg_widgetVariant
            onPicked: value => cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: [{label: i18n("Toggles"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")}, {label: i18n("Volume dots"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")}].concat(
                [["wifi", false], ["wifi", true], ["bluetooth", false], ["bluetooth", true], ["airplane", false], ["airplane", true],
                 ["volume", false], ["volume", true]].map((v, i) => ({
                    label: [i18n("Wi-Fi"), i18n("Wi-Fi circle"), i18n("Bluetooth"), i18n("Bluetooth circle"), i18n("Airplane"), i18n("Airplane circle"),
                        i18n("Volume ring"), i18n("Volume pill")][i],
                    value: 2 + i, source: Qt.resolvedUrl("../everything/EveryToggle.qml"), props: {kind: v[0], round: v[1], on: i % 2 === 0, volume: 0.4}
                })))
        }
        Glassy.ThemeSettings { id: theme }
    }
}
