import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: configGeneral

    property int cfg_widgetVariant
    property alias cfg_location: locationField.text
    property alias cfg_temperatureUnit: temperatureUnitCombo.currentIndex
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
                {label: i18n("Full"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")},
                {label: i18n("Circular"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")},
                {label: i18n("Circle Pages"), value: 2, image: Qt.resolvedUrl("../previews/style-2-dark.png")},
                {label: i18n("Square"), value: 3, source: Qt.resolvedUrl("../everything/EveryWeather.qml"),
                 props: {temperature: "17", condition: i18n("Clear"), code: 0}}
            ]
        }

        // --- Location ---
        RowLayout {
            Label {
                text: i18n("Location:")
                Layout.alignment: Qt.AlignLeft
            }

            TextField {
                id: locationField
                placeholderText: i18n("e.g., Victoria, Canada or Home|48.4284,-123.3656")
                Layout.fillWidth: true
            }
        }

        Label {
            text: i18n("Enter a city name, optionally followed by a country (e.g., 'Victoria, Canada'). For ambiguous or hard-to-find places, enter exact coordinates as 'Label|latitude,longitude'.")
            font.pointSize: 9
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#333333"
            opacity: 0.3
        }

        // --- Temperature Unit ---
        RowLayout {
            Label {
                text: i18n("Temperature Unit:")
                Layout.alignment: Qt.AlignLeft
            }

            ComboBox {
                id: temperatureUnitCombo
                model: [i18n("Celsius (\u00B0C)"), i18n("Fahrenheit (\u00B0F)")]
                Layout.fillWidth: true
            }
        }

        Label {
            text: i18n("Choose between Celsius and Fahrenheit for temperature display.")
            font.pointSize: 9
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#333333"
            opacity: 0.3
        }

        Glassy.ThemeSettings { id: theme }

        Item {
            Layout.fillHeight: true
        }
    }
}
