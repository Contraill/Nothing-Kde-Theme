import QtQuick
import QtQuick.Controls
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: configGeneral

    property int cfg_widgetVariant
    property int cfg_monthStyle
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome

    // 2 and 3 were the month of dots and of numbers; now the pages' calendar.
    Component.onCompleted: if (cfg_widgetVariant >= 2) {
        cfg_monthStyle = cfg_widgetVariant - 1;
        cfg_widgetVariant = 0;
    }

    ColumnLayout {
        spacing: 10

        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: configGeneral.cfg_widgetVariant
            onPicked: value => configGeneral.cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: [
                {label: i18n("Pages"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")},
                {label: i18n("Pill"), value: 1, source: Qt.resolvedUrl("../everything/EveryDate.qml"), props: {layout: "pill"}}
            ]
        }
        // What a turned page shows.
        Glassy.StyleCards {
            Layout.fillWidth: true
            visible: configGeneral.cfg_widgetVariant === 0
            title: i18n("Calendar:")
            selected: configGeneral.cfg_monthStyle
            onPicked: value => configGeneral.cfg_monthStyle = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: [
                {label: i18n("Classic"), value: 0, image: Qt.resolvedUrl("../previews/calendar-0-dark.png")},
                {label: i18n("Dots"), value: 1, source: Qt.resolvedUrl("../everything/EveryDate.qml"), props: {layout: "dots"}},
                {label: i18n("Numbers"), value: 2, source: Qt.resolvedUrl("../everything/EveryDate.qml"), props: {layout: "numbers"}}
            ]
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: configGeneral.cfg_widgetVariant === 0
            text: i18n("Turn the page at its corner to see the calendar; the wheel leafs through the months.")
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: 9
        }

        Glassy.ThemeSettings { id: theme }

        Item {
            Layout.fillHeight: true
        }
    }
}
