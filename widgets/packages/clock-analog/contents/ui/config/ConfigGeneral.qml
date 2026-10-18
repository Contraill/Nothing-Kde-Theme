// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property int cfg_widgetVariant
    property alias cfg_smoothHands: smooth.checked
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent

    ColumnLayout {
        spacing: 10
        RowLayout {
            QQC2.Label { text: i18n("Style:") }
            QQC2.ComboBox {
                model: [i18n("Classic"), i18n("Minimal"), i18n("Dots")]
                currentIndex: Math.max(0, cfg_widgetVariant)
                onActivated: cfg_widgetVariant = currentIndex
            }
        }
        QQC2.CheckBox { id: smooth; text: i18n("Sweeping second hand") }
        Glassy.ThemeSettings { id: theme }
    }
}
