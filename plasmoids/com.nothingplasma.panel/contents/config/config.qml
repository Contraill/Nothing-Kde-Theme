import QtQuick
import org.kde.plasma.configuration as PlasmaConfig

PlasmaConfig.ConfigModel {
    PlasmaConfig.ConfigCategory {
        name: i18nc("@title:group for configuration dialog page", "General") // qmllint disable unqualified
        icon: "preferences-desktop-plasma"
        source: "ConfigGeneral.qml"
    }
}
