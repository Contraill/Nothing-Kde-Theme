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
                model: [i18n("Page: the day, click for the month"), i18n("Month as dots"), i18n("Pill with the month's progress")]
            }
        }
        Glassy.ThemeSettings { id: theme }
    }
}
