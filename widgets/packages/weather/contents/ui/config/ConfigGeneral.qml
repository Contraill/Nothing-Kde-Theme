// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property int cfg_widgetVariant
    property alias cfg_location: location.text
    property alias cfg_temperatureUnit: unit.currentIndex
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent

    ColumnLayout {
        spacing: 10
        RowLayout {
            QQC2.Label { text: i18n("Style:") }
            QQC2.ComboBox {
                model: [i18n("Full"), i18n("Pill and circles"), i18n("Circle"), i18n("Pill")]
                currentIndex: Math.max(0, cfg_widgetVariant)
                onActivated: cfg_widgetVariant = currentIndex
            }
        }
        RowLayout {
            QQC2.Label { text: i18n("City:") }
            QQC2.TextField { id: location; Layout.fillWidth: true; placeholderText: i18n("A city, or label|latitude,longitude") }
        }
        RowLayout {
            QQC2.Label { text: i18n("Unit:") }
            QQC2.ComboBox { id: unit; model: ["°C", "°F"] }
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Forecasts by Open-Meteo (open-meteo.com, CC BY 4.0); the city name or coordinates are sent there.")
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: 9
        }
        Glassy.ThemeSettings { id: theme }
    }
}
