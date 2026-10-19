import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: configAppearance

    property int cfg_widgetVariant
    property alias cfg_smoothHands: smoothHandsCheckbox.checked
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
                {label: i18n("Swiss Railway"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")},
                {label: i18n("Minimalist"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")},
                {label: i18n("Circle"), value: 2, source: Qt.resolvedUrl("../everything/EveryAnalog.qml"), props: {round: true, hours: 10, minutes: 9}},
                {label: i18n("Square"), value: 3, source: Qt.resolvedUrl("../everything/EveryAnalog.qml"), props: {round: false, hours: 10, minutes: 9}}
            ]
        }

        // --- Smooth hands ---
        RowLayout {
            CheckBox {
                id: smoothHandsCheckbox
                text: i18n("Smooth Moving Second Hand")
            }
        }

        Label {
            text: i18n("Update second hand every 50ms instead of 1000ms ( 1s ) for a smoother motion")
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
