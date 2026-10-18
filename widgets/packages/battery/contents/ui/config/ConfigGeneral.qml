// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property alias cfg_widgetVariant: style.currentIndex
    property string cfg_deviceType
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent

    ColumnLayout {
        spacing: 10
        RowLayout {
            QQC2.Label { text: i18n("Style:") }
            QQC2.ComboBox { id: style; model: [i18n("Devices"), i18n("Ring"), i18n("Block")] }
        }
        RowLayout {
            QQC2.Label { text: i18n("This computer is a:") }
            QQC2.ComboBox {
                model: [i18n("Laptop"), i18n("Desktop")]
                currentIndex: cfg_deviceType === "computer" ? 1 : 0
                onActivated: cfg_deviceType = currentIndex === 1 ? "computer" : "laptop"
            }
        }
        Glassy.ThemeSettings { id: theme }
    }
}
