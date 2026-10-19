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
                model: [i18n("Note"), i18n("Mantra pill"), i18n("EveryThing mantra (one line at a time)")]
            }
        }
        Glassy.EveryStyleCards {
            Layout.fillWidth: true
            selected: style.currentIndex
            onPicked: value => style.currentIndex = value
            styles: [{label: i18n("Mantra"), value: 2, source: Qt.resolvedUrl("../everything/EveryMantra.qml"), props: {phrases: [i18n("Embrace the void")]}}]
        }
        Glassy.ThemeSettings { id: theme }
    }
}
