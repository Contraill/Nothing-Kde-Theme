import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: configGeneral

    property alias cfg_widgetVariant: styleCombo.currentIndex
    property alias cfg_themeMode: themeModeCombo.currentIndex
    property alias cfg_useSystemAccent: useSystemAccentCheckbox.checked

    ColumnLayout {
        spacing: 10

        RowLayout {
            Label { text: i18n("Style:") }
            ComboBox {
                id: styleCombo
                Layout.fillWidth: true
                model: [i18n("Cards"), i18n("EveryThing player"), i18n("EveryThing player pill")]
            }
        }
        Glassy.EveryStyleCards {
            Layout.fillWidth: true
            selected: styleCombo.currentIndex
            onPicked: value => styleCombo.currentIndex = value
            styles: [
                {label: i18n("Player"), value: 1, source: Qt.resolvedUrl("../everything/EveryPlayer.qml"), props: {title: "Nothing KDE", artist: "EveryThing-UI", progress: 0.4}},
                {label: i18n("Pill"), value: 2, source: Qt.resolvedUrl("../everything/EveryPlayer.qml"), props: {pill: true, title: "Nothing KDE", artist: "EveryThing-UI", progress: 0.4}}
            ]
        }

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

        Item {
            Layout.fillHeight: true
        }
    }
}
