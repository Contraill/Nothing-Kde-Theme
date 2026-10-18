pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../island/ui" as Island

KCM.SimpleKCM {
    id: root

    property alias cfg_islandWeatherCity: islandWeatherCity.text
    property string cfg_islandLanguage: "auto"
    property alias cfg_launcherWidthPercent: launcherWidthPercent.value
    property alias cfg_launcherHeightPercent: launcherHeightPercent.value
    property alias cfg_taskAreaMaxPercent: taskAreaMaxPercent.value
    property alias cfg_taskPreviewWidthPercent: taskPreviewWidthPercent.value
    property alias cfg_taskPreviewHeightPercent: taskPreviewHeightPercent.value
    property alias cfg_panelOpacity: panelOpacity.value
    property alias cfg_popupOpacity: popupOpacity.value
    property alias cfg_glassBlur: glassBlur.checked
    property alias cfg_autoWallpaper: autoWallpaper.checked

    component PercentSpin: QQC2.SpinBox {
        from: 10
        to: 90
        stepSize: 1
        textFromValue: function(value) { return value + "%" }
        valueFromText: function(text) { return parseInt(text) }
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        Kirigami.Heading {
            Kirigami.FormData.isSection: true
            text: "Nothing Island + Dock"
            level: 3
        }

        QQC2.Label {
            Kirigami.FormData.label: Island.Cfg.t("PANEL THICKNESS")
            text: Island.Cfg.t("PANELS NOTE")
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 460
        }

        QQC2.SpinBox {
            id: panelOpacity
            Kirigami.FormData.label: Island.Cfg.t("PANEL OPACITY")
            from: 20; to: 98; stepSize: 2
            textFromValue: function(value) { return value + "%" }
            valueFromText: function(text) { return parseInt(text) }
        }

        QQC2.SpinBox {
            id: popupOpacity
            Kirigami.FormData.label: Island.Cfg.t("EXTENSION OPACITY")
            from: 18; to: 96; stepSize: 2
            textFromValue: function(value) { return value + "%" }
            valueFromText: function(text) { return parseInt(text) }
        }

        QQC2.CheckBox {
            id: glassBlur
            Kirigami.FormData.label: Island.Cfg.t("GLASS EFFECT")
            text: Island.Cfg.t("GLASS BLUR OPTION")
        }

        QQC2.CheckBox {
            id: autoWallpaper
            Kirigami.FormData.label: Island.Cfg.t("THEME WALLPAPER")
            text: Island.Cfg.t("THEME WALLPAPER OPTION")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: Island.Cfg.t("PANEL GEOMETRY")
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: Island.Cfg.t("ISLAND LANGUAGE")
            // "auto" plus one entry per catalog in po/panel.
            readonly property var codes: ["auto"].concat(Island.Cfg.languages)
            model: codes.map(code => code === "auto" ? Island.Cfg.t("SYSTEM LANGUAGE") : Island.Cfg.languageName(code))
            currentIndex: Math.max(0, codes.indexOf(root.cfg_islandLanguage))
            onActivated: root.cfg_islandLanguage = codes[currentIndex]
        }
        QQC2.TextField {
            id: islandWeatherCity
            Kirigami.FormData.label: Island.Cfg.t("WEATHER CITY")
            placeholderText: Island.Cfg.t("AUTO CITY")
        }

        PercentSpin {
            id: launcherWidthPercent
            Kirigami.FormData.label: Island.Cfg.t("LAUNCHER MIN WIDTH")
            from: 22; to: 60
        }

        PercentSpin {
            id: launcherHeightPercent
            Kirigami.FormData.label: Island.Cfg.t("LAUNCHER HEIGHT")
            from: 24; to: 65
        }

        PercentSpin {
            id: taskAreaMaxPercent
            Kirigami.FormData.label: Island.Cfg.t("TASK AREA MAX WIDTH")
            from: 18; to: 60
        }

        PercentSpin {
            id: taskPreviewWidthPercent
            Kirigami.FormData.label: Island.Cfg.t("TASK PREVIEW WIDTH")
            from: 28; to: 70
        }

        PercentSpin {
            id: taskPreviewHeightPercent
            Kirigami.FormData.label: Island.Cfg.t("TASK PREVIEW HEIGHT")
            from: 14; to: 34
        }

    }
}
