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
            styles: [
                {label: i18n("Note"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")},
                {label: i18n("Mantra pill"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")},
                {label: i18n("Mantra"), value: 2, source: Qt.resolvedUrl("../everything/EveryMantra.qml"), props: {phrases: [i18n("Embrace the void")]}}
            ]
        }
        Glassy.ThemeSettings { id: theme }
    }
}
