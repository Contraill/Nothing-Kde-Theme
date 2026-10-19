import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: configGeneral

    property int cfg_widgetVariant
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome
    property alias cfg_transparent: theme.transparent

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
                {label: i18n("Cards"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")},
                {label: i18n("Player"), value: 1, source: Qt.resolvedUrl("../everything/EveryPlayer.qml"), props: {title: "Glow", artist: "Nothing", progress: 0.4}},
                {label: i18n("Pill"), value: 2, source: Qt.resolvedUrl("../everything/EveryPlayer.qml"), props: {pill: true, title: "Glow", artist: "Nothing", progress: 0.4}}
            ]
        }

        Glassy.ThemeSettings { id: theme; cardOption: true }

        Item {
            Layout.fillHeight: true
        }
    }
}
