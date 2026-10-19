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
            styles: [{label: i18n("Year ring"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")}, {label: i18n("Day to year"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")}].concat(
                [["year", false], ["year", true], ["countdown", false], ["countdown", true]].map((v, i) => ({
                    label: [i18n("Year"), i18n("Year circle"), i18n("Countdown"), i18n("Countdown circle")][i], value: 2 + i,
                    source: Qt.resolvedUrl("../everything/EveryProgress.qml"),
                    props: {kind: v[0], round: v[1], yearFraction: 0.8, dayFraction: 0.4, dayOfYear: 292}
                })))
        }
        Glassy.ThemeSettings { id: theme }
    }
}
