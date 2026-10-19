import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: configAppearance

    property int cfg_widgetVariant
    property alias cfg_borderEnabled: borderEnabledCheckbox.checked
    property alias cfg_borderSize: borderSizeSlider.value
    property alias cfg_pillShapeEnabled: pillShapeCheckbox.checked
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
            styles: [{label: i18n("Frame"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")}].concat(
                ["square", "circle", "wide", "wide-pill"].map((shape, i) => ({
                    label: [i18n("Square"), i18n("Circle"), i18n("Wide"), i18n("Wide pill")][i], value: i + 1,
                    source: Qt.resolvedUrl("../everything/EveryPhoto.qml"), props: {shape: shape}
                })))
        }

        // Border Settings Section
        Label {
            text: i18n("Border Settings")
            font.bold: true
            font.pointSize: 11
        }

        RowLayout {
            CheckBox {
                id: borderEnabledCheckbox
                text: i18n("Enable Borders")
            }
        }

        Label {
            text: i18n("Adds margin around the image to reveal the dark background, creating a frame effect")
            font.pointSize: 9
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            enabled: borderEnabledCheckbox.checked

            Label {
                text: i18n("Border Size:")
                Layout.alignment: Qt.AlignLeft
            }

            Slider {
                id: borderSizeSlider
                from: 0
                to: 50
                stepSize: 1
                Layout.fillWidth: true
            }

            Label {
                text: Math.round(borderSizeSlider.value) + "px"
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#333333"
            opacity: 0.3
        }

        // Shape Settings Section
        Label {
            text: i18n("Shape Settings")
            font.bold: true
            font.pointSize: 11
        }

        RowLayout {
            CheckBox {
                id: pillShapeCheckbox
                text: i18n("Pill Shape")
            }
        }

        Label {
            text: i18n("Automatically creates a circle (if square) or pill shape (if rectangular). When disabled, uses standard rounded corners.")
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
