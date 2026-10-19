import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: configAppearance

    property int cfg_fontStyle
    property alias cfg_showDate: showDateCheckbox.checked
    property alias cfg_use24HourFormat: use24HourCheckbox.checked
    property alias cfg_useDarkerFont: useDarkerFontCheckbox.checked
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome

    ColumnLayout {
        spacing: 10

        Glassy.StyleCards {
            Layout.fillWidth: true
            title: i18n("Font Style:")
            selected: configAppearance.cfg_fontStyle === 1 ? 7 : configAppearance.cfg_fontStyle
            onPicked: value => configAppearance.cfg_fontStyle = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            // 1, Dot Matrix, became the dot face (7).
            styles: [[i18n("Dotted"), 0], [i18n("Serif"), 2], [i18n("Segmented"), 3], [i18n("Segmented Sharp"), 4]].map(v => ({
                label: v[0], value: v[1], image: Qt.resolvedUrl("../previews/style-" + v[1] + "-dark.png")
            })).concat(["blocks", "blocks-dual", "dots", "bubbles", "bubbles-inverse", "outline"].map((face, i) => ({
                label: [i18n("Blocks"), i18n("Two tone"), i18n("Dots"), i18n("Bubbles"), i18n("Inverted"), i18n("Outline")][i],
                value: 5 + i,
                source: Qt.resolvedUrl("../everything/EveryBigClock.qml"),
                props: {face: face, time: "10:09", dotFamily: "", outlineFamily: ""}
            })))
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#333333"
            opacity: 0.3
        }

        RowLayout {
            CheckBox {
                id: showDateCheckbox
                text: i18n("Show Date")
            }
        }

        Label {
            text: i18n("Display the current date above the time (e.g., \"Thu, 31 Jan\")")
            font.pointSize: 9
            opacity: 0.7
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            CheckBox {
                id: use24HourCheckbox
                text: i18n("Use 24-Hour Format")
            }
        }

        Label {
            text: i18n("Show time in 24-hour format (e.g., 14:30) instead of 12-hour format (e.g., 2:30)")
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

        RowLayout {
            CheckBox {
                id: useDarkerFontCheckbox
                text: i18n("Use Darker Font Color")
            }
        }

        Label {
            text: i18n("Use a darker font color for better visibility on lighter backgrounds")
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
