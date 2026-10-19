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

    ColumnLayout {
        spacing: 10

        Glassy.ThemeSettings { id: theme }

        Item {
            Layout.fillHeight: true
        }
    }
}
