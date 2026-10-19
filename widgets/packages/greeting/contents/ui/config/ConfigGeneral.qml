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
                model: [i18n("Pill"), i18n("Square")]
            }
        }
        Glassy.EveryStyleCards {
            Layout.fillWidth: true
            selected: style.currentIndex
            onPicked: value => style.currentIndex = value
            styles: [
                {label: i18n("Pill"), value: 0, source: Qt.resolvedUrl("../everything/EveryGreeting.qml"), props: {}},
                {label: i18n("Square"), value: 1, source: Qt.resolvedUrl("../everything/EveryGreeting.qml"), props: {square: true}}
            ]
        }
        Glassy.ThemeSettings { id: theme }
    }
}
