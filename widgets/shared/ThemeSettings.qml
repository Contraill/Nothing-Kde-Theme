// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

// Theme rows shared by every widget's settings page; the page aliases
// cfg_themeMode, cfg_useSystemAccent and cfg_monochrome to these controls.
ColumnLayout {
    property alias themeMode: mode.currentIndex
    property alias useSystemAccent: accent.checked
    property alias monochrome: mono.checked
    spacing: 6

    RowLayout {
        QQC2.Label { text: i18n("Theme:") }
        QQC2.ComboBox {
            id: mode
            Layout.fillWidth: true
            model: [i18n("Dark"), i18n("Light"), i18n("Follow System")]
        }
    }
    QQC2.CheckBox {
        id: mono
        text: i18n("Monochrome")
    }
    QQC2.CheckBox {
        id: accent
        enabled: !mono.checked
        text: i18n("Use system accent color")
    }
    QQC2.Label {
        Layout.fillWidth: true
        text: i18n("Follow System matches the KDE light or dark scheme. Monochrome drops the red marks; the system accent replaces Nothing red.")
        wrapMode: Text.Wrap
        opacity: 0.7
        font.pointSize: 9
    }
}
