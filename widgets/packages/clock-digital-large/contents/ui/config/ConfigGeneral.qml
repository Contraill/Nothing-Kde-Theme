// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property alias cfg_fontStyle: face.currentIndex
    property alias cfg_showDate: date.checked
    property alias cfg_use24HourFormat: hours24.checked
    property alias cfg_useDarkerFont: dim.checked
    property alias cfg_showBackground: background.checked
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent

    ColumnLayout {
        spacing: 10
        RowLayout {
            QQC2.Label { text: i18n("Face:") }
            QQC2.ComboBox { id: face; model: [i18n("Dots"), i18n("Two-tone dots"), i18n("Serif"), i18n("Grotesk")] }
        }
        QQC2.CheckBox { id: date; text: i18n("Show the date") }
        QQC2.CheckBox { id: hours24; text: i18n("24-hour clock") }
        QQC2.CheckBox { id: dim; text: i18n("Softer colour") }
        QQC2.CheckBox { id: background; text: i18n("Card behind the clock") }
        Glassy.ThemeSettings { id: theme }
    }
}
