import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: configGeneral

    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome
    property alias cfg_focusMinutes: focusMinutes.value
    property alias cfg_breakMinutes: breakMinutes.value
    property alias cfg_longBreakMinutes: longBreakMinutes.value
    property alias cfg_roundsBeforeLongBreak: roundsBeforeLongBreak.value

    ColumnLayout {
        spacing: 10

        Glassy.ThemeSettings { id: theme }

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
