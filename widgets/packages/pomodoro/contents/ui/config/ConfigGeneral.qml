import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configGeneral

    property alias cfg_themeMode: themeModeCombo.currentIndex
    property alias cfg_useSystemAccent: useSystemAccentCheckbox.checked
    property alias cfg_focusMinutes: focusMinutes.value
    property alias cfg_breakMinutes: breakMinutes.value
    property alias cfg_longBreakMinutes: longBreakMinutes.value
    property alias cfg_roundsBeforeLongBreak: roundsBeforeLongBreak.value

    ColumnLayout {
        spacing: 10

        RowLayout {
            Label {
                text: i18n("Theme:")
                Layout.alignment: Qt.AlignLeft
            }

            ComboBox {
                id: themeModeCombo
                model: [i18n("Dark"), i18n("Light"), i18n("Follow System")]
                Layout.fillWidth: true
            }
        }

        Label {
            text: i18n("Dark: Nothing's signature dark aesthetic. Light: Nothing's light palette. Follow System: Matches your KDE dark/light scheme.")
            font.pointSize: 9
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            CheckBox {
                id: useSystemAccentCheckbox
                text: i18n("Use system accent color")
            }
        }

        Label {
            text: i18n("Replace Nothing's red accent with your KDE system highlight color while keeping the Nothing aesthetic.")
            font.pointSize: 9
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        GridLayout {
            columns: 2
            Label { text: i18n("Focus (minutes):") }
            SpinBox { id: focusMinutes; from: 1; to: 180 }
            Label { text: i18n("Break (minutes):") }
            SpinBox { id: breakMinutes; from: 1; to: 60 }
            Label { text: i18n("Long break (minutes):") }
            SpinBox { id: longBreakMinutes; from: 1; to: 90 }
            Label { text: i18n("Rounds before a long break:") }
            SpinBox { id: roundsBeforeLongBreak; from: 1; to: 12 }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
