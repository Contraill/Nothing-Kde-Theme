import QtQuick
import org.kde.plasma.configuration as PlasmaConfig
import "../island/ui" as Island

PlasmaConfig.ConfigModel {
    PlasmaConfig.ConfigCategory {
        name: Island.Cfg.t("GENERAL")
        icon: "preferences-desktop-plasma"
        source: "ConfigGeneral.qml"
    }
}
