import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "../../../../../shared" as Glassy
import "." as Config

KCM.SimpleKCM {
    id: configGeneral

    property int cfg_widgetVariant
    property alias cfg_use24HourFormat: use24HourCheckbox.checked
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome
    property alias cfg_transparent: theme.transparent
    property alias cfg_cityName: cityNameField.text
    property string cfg_timeZone

    Config.TimezonesData {
        id: timezonesData
    }

    Component.onCompleted: {
        loadTimezones()
    }

    function loadTimezones() {
        timezoneModel.clear()
        for (var i = 0; i < timezonesData.timezones.length; i++) {
            var tz = timezonesData.timezones[i]
            var offsetStr = formatOffset(tz.offset)
            var displayName = tz.city + ", " + tz.country + " (" + offsetStr + ")"
            timezoneModel.append({
                "display": displayName,
                "value": tz.id,
                "city": tz.city
            })
        }
        selectCurrentTimezone()
    }

    function formatOffset(offset) {
        var prefix = offset >= 0 ? "UTC+" : "UTC"
        if (offset === 0) return "UTC+0"

        var absOffset = Math.abs(offset)
        var hours = Math.floor(absOffset)
        var minutes = Math.round((absOffset - hours) * 60)

        if (minutes === 0) {
            return prefix + hours
        } else {
            return prefix + hours + ":" + (minutes < 10 ? "0" : "") + minutes
        }
    }

    function selectCurrentTimezone() {
        for (var i = 0; i < timezoneModel.count; i++) {
            if (timezoneModel.get(i).value === cfg_timeZone) {
                timezoneCombo.currentIndex = i
                return
            }
        }
        if (timezoneModel.count > 0) {
            timezoneCombo.currentIndex = 0
        }
    }

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
                {label: i18n("Digital Clock"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")},
                {label: i18n("World Clock"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")},
                {label: i18n("Tall pill"), value: 2, source: Qt.resolvedUrl("../everything/EveryDigital.qml"), props: {layout: "vertical", hour: "10", minute: "09"}},
                {label: i18n("Wide pill"), value: 3, source: Qt.resolvedUrl("../everything/EveryDigital.qml"), props: {layout: "horizontal", hour: "10", minute: "09"}},
                {label: i18n("Square"), value: 4, source: Qt.resolvedUrl("../everything/EveryDigital.qml"), props: {layout: "square", hour: "10", minute: "09"}}
            ]
        }

        // --- Digital clock settings (variant 0 and the EveryThing styles) ---
        RowLayout {
            visible: cfg_widgetVariant !== 1
            CheckBox {
                id: use24HourCheckbox
                text: i18n("Use 24-Hour Format")
            }
        }

        Label {
            visible: cfg_widgetVariant === 0
            text: i18n("Show time in 24-hour format (e.g., 14:30) instead of 12-hour format (e.g., 2:30)")
            font.pointSize: 9
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Rectangle {
            visible: cfg_widgetVariant === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#333333"
            opacity: 0.3
        }

        // --- World clock settings (variant 1) ---
        Label {
            visible: cfg_widgetVariant === 1
            text: i18n("City Name:")
        }

        TextField {
            id: cityNameField
            visible: cfg_widgetVariant === 1
            placeholderText: i18n("e.g., Famagusta, New York, Tokyo")
            Layout.fillWidth: true
        }

        Label {
            visible: cfg_widgetVariant === 1
            text: i18n("Enter the city name to display on the widget.")
            font.pointSize: 9
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Rectangle {
            visible: cfg_widgetVariant === 1
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#333333"
            opacity: 0.3
        }

        Label {
            visible: cfg_widgetVariant === 1
            text: i18n("Time Zone:")
        }

        ComboBox {
            id: timezoneCombo
            visible: cfg_widgetVariant === 1
            Layout.fillWidth: true
            textRole: "display"

            model: ListModel {
                id: timezoneModel
            }

            onActivated: {
                if (currentIndex >= 0 && currentIndex < timezoneModel.count) {
                    cfg_timeZone = timezoneModel.get(currentIndex).value
                    cfg_cityName = timezoneModel.get(currentIndex).city
                }
            }
        }

        Label {
            visible: cfg_widgetVariant === 1
            text: i18n("Select a timezone from the list above. The widget will display the time for the selected location.")
            font.pointSize: 9
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Rectangle {
            visible: cfg_widgetVariant === 1
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#333333"
            opacity: 0.3
        }

        Glassy.ThemeSettings { id: theme; cardOption: true }

        Item {
            Layout.fillHeight: true
        }
    }
}
