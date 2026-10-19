// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property alias cfg_widgetVariant: style.currentIndex
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent

    ColumnLayout {
        spacing: 10
        RowLayout {
            QQC2.Label { text: i18n("Style:") }
            QQC2.ComboBox {
                id: style
                model: [i18n("Toggles and volume"), i18n("Volume pill"),
                    i18n("EveryThing Wi-Fi"), i18n("EveryThing Wi-Fi circle"), i18n("EveryThing Bluetooth"), i18n("EveryThing Bluetooth circle"),
                    i18n("EveryThing airplane mode"), i18n("EveryThing airplane mode circle"), i18n("EveryThing volume"), i18n("EveryThing volume pill")]
            }
        }
        Glassy.EveryStyleCards {
            Layout.fillWidth: true
            selected: style.currentIndex
            onPicked: value => style.currentIndex = value
            styles: [["wifi", false], ["wifi", true], ["bluetooth", false], ["bluetooth", true], ["airplane", false], ["airplane", true],
                     ["volume", false], ["volume", true]].map((v, i) => ({
                label: [i18n("Wi-Fi"), i18n("Wi-Fi circle"), i18n("Bluetooth"), i18n("Bluetooth circle"), i18n("Airplane"), i18n("Airplane circle"), i18n("Volume"), i18n("Volume pill")][i],
                value: 2 + i, source: Qt.resolvedUrl("../everything/EveryToggle.qml"), props: {kind: v[0], round: v[1], on: i % 2 === 0, volume: 0.4}
            }))
        }
        Glassy.ThemeSettings { id: theme }
    }
}
