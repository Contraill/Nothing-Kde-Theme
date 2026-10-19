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
                model: [i18n("Rings"), i18n("Bars"), i18n("Pill"), i18n("EveryThing status"), i18n("EveryThing CPU"),
                    i18n("EveryThing CPU pill"), i18n("EveryThing network"), i18n("EveryThing network pill")]
            }
        }
        Glassy.EveryStyleCards {
            Layout.fillWidth: true
            selected: style.currentIndex
            onPicked: value => style.currentIndex = value
            styles: ["status", "cpu", "cpu-pill", "network", "network-pill"].map((layout, i) => ({
                label: [i18n("Status"), i18n("CPU"), i18n("CPU pill"), i18n("Network"), i18n("Network pill")][i], value: 3 + i,
                source: Qt.resolvedUrl("../everything/EverySystem.qml"),
                props: {layout: layout, cpu: 23, memory: 61, diskUsed: 509e9, diskTotal: 920e9, battery: 78, download: "472.0 KB", upload: "8.9 KB"}
            }))
        }
        Glassy.ThemeSettings { id: theme }
    }
}
