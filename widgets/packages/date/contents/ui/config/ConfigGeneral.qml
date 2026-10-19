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

    ColumnLayout {
        spacing: 10

        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: cfg_widgetVariant
            onPicked: value => cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: [{label: i18n("Pages"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")}].concat(
                ["pill", "dots", "numbers"].map((layout, i) => ({
                    label: [i18n("Pill"), i18n("Dots"), i18n("Numbers")][i], value: i + 1,
                    source: Qt.resolvedUrl("../everything/EveryDate.qml"), props: {layout: layout}
                })))
        }

        Glassy.ThemeSettings { id: theme }

        Item {
            Layout.fillHeight: true
        }
    }
}
