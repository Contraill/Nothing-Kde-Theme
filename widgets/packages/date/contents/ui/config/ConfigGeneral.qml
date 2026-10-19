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
                model: [i18n("Pages"), i18n("EveryThing pill"), i18n("EveryThing month of dots"), i18n("EveryThing month of numbers")]
            }
        }
        Glassy.EveryStyleCards {
            Layout.fillWidth: true
            selected: styleCombo.currentIndex
            onPicked: value => styleCombo.currentIndex = value
            styles: ["pill", "dots", "numbers"].map((layout, i) => ({
                label: [i18n("Pill"), i18n("Dots"), i18n("Numbers")][i], value: i + 1,
                source: Qt.resolvedUrl("../everything/EveryDate.qml"), props: {layout: layout}
            }))
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
