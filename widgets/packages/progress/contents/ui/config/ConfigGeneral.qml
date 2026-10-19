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
                model: [i18n("Year ring"), i18n("Day, week, month and year"), i18n("EveryThing year"), i18n("EveryThing year circle"),
                    i18n("EveryThing countdown"), i18n("EveryThing countdown circle")]
            }
        }
        Glassy.EveryStyleCards {
            Layout.fillWidth: true
            selected: style.currentIndex
            onPicked: value => style.currentIndex = value
            styles: [["year", false], ["year", true], ["countdown", false], ["countdown", true]].map((v, i) => ({
                label: [i18n("Year"), i18n("Year circle"), i18n("Countdown"), i18n("Countdown circle")][i], value: 2 + i,
                source: Qt.resolvedUrl("../everything/EveryProgress.qml"),
                props: {kind: v[0], round: v[1], yearFraction: 0.8, dayFraction: 0.4, dayOfYear: 292}
            }))
        }
        Glassy.ThemeSettings { id: theme }
    }
}
