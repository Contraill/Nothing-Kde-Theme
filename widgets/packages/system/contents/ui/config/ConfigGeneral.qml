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
            styles: [{label: i18n("Rings"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")}, {label: i18n("Bars"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")}, {label: i18n("Pill"), value: 2, image: Qt.resolvedUrl("../previews/style-2-dark.png")}].concat(
                ["status", "cpu", "cpu-pill", "network", "network-pill"].map((layout, i) => ({
                    label: [i18n("Status"), i18n("CPU"), i18n("CPU pill"), i18n("Network"), i18n("Network pill")][i], value: 3 + i,
                    source: Qt.resolvedUrl("../everything/EverySystem.qml"),
                    props: {layout: layout, cpu: 23, memory: 61, diskUsed: 509e9, diskTotal: 920e9, battery: 78, download: "472.0 KB", upload: "8.9 KB"}
                })))
        }
        Glassy.ThemeSettings { id: theme }
    }
}
