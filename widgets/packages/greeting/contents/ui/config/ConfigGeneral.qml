// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property int cfg_widgetVariant
    property alias cfg_showTime: showTime.checked
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome
    property alias cfg_transparent: theme.transparent

    ColumnLayout {
        spacing: 10
        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: cfg_widgetVariant
            onPicked: value => cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: [
                {label: i18n("Pill"), value: 0, source: Qt.resolvedUrl("../everything/EveryGreeting.qml"), props: {showTime: showTime.checked}},
                {label: i18n("Square"), value: 1, source: Qt.resolvedUrl("../everything/EveryGreeting.qml"), props: {square: true, showTime: showTime.checked}}
            ]
        }
        QQC2.CheckBox {
            id: showTime
            text: i18n("Show the time")
        }
        Glassy.ThemeSettings { id: theme; cardOption: true }
    }
}
