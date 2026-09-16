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
    property alias cfg_wifiHeightPercent: wifiHeightPercent.value
    property alias cfg_bluetoothHeightPercent: bluetoothHeightPercent.value
    property alias cfg_audioHeightPercent: audioHeightPercent.value
    property alias cfg_displayHeightPercent: displayHeightPercent.value
    property alias cfg_powerDetailHeightPercent: powerDetailHeightPercent.value
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
            Kirigami.FormData.label: i18nc("@label", "Panel thickness:") // qmllint disable unqualified
            text: Island.Cfg.turkish ? "Üst ada ve alt dock iki bağımsız Plasma panelidir. Cam ayarları dock içindir." : "The top island and bottom dock are independent Plasma panels. Glass settings apply to the dock."
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 460
        }

        QQC2.SpinBox {
            id: panelOpacity
            Kirigami.FormData.label: i18nc("@label:spinbox", "Panel opacity:") // qmllint disable unqualified
            from: 20; to: 98; stepSize: 2
            textFromValue: function(value) { return value + "%" }
            valueFromText: function(text) { return parseInt(text) }
        }

        QQC2.SpinBox {
            id: popupOpacity
            Kirigami.FormData.label: i18nc("@label:spinbox", "Extension opacity:") // qmllint disable unqualified
            from: 18; to: 96; stepSize: 2
            textFromValue: function(value) { return value + "%" }
            valueFromText: function(text) { return parseInt(text) }
        }

        QQC2.CheckBox {
            id: glassBlur
            Kirigami.FormData.label: i18nc("@label", "Glass effect:") // qmllint disable unqualified
            text: i18nc("@option:check", "Use KWin background blur behind Nothing extensions") // qmllint disable unqualified
        }

        QQC2.CheckBox {
            id: autoWallpaper
            Kirigami.FormData.label: i18nc("@label", "Theme wallpaper:") // qmllint disable unqualified
            text: Island.Cfg.turkish ? "Masaüstü ve kilit ekranı duvar kâğıdını temayla değiştir" : "Switch desktop and lock-screen wallpapers with the theme"
        }


        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Panel geometry") // qmllint disable unqualified
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: Island.Cfg.t("ISLAND LANGUAGE")
            model: [Island.Cfg.t("SYSTEM LANGUAGE"), "Türkçe", "English"]
            currentIndex: root.cfg_islandLanguage === "en" ? 2 : root.cfg_islandLanguage === "tr" ? 1 : 0
            onActivated: root.cfg_islandLanguage = ["auto", "tr", "en"][currentIndex]
        }
        QQC2.TextField {
            id: islandWeatherCity
            Kirigami.FormData.label: Island.Cfg.t("WEATHER CITY")
            placeholderText: Island.Cfg.t("AUTO CITY")
        }

        PercentSpin {
            id: launcherWidthPercent
            Kirigami.FormData.label: i18nc("@label", "Launcher minimum width:") // qmllint disable unqualified
            from: 22; to: 60
        }

        PercentSpin {
            id: launcherHeightPercent
            Kirigami.FormData.label: i18nc("@label", "Launcher height:") // qmllint disable unqualified
            from: 24; to: 65
        }

        PercentSpin {
            id: taskAreaMaxPercent
            Kirigami.FormData.label: i18nc("@label", "Task area maximum width:") // qmllint disable unqualified
            from: 18; to: 60
        }

        PercentSpin {
            id: wifiHeightPercent
            Kirigami.FormData.label: i18nc("@label", "Wi-Fi detail height:") // qmllint disable unqualified
            from: 20; to: 60
        }

        PercentSpin {
            id: bluetoothHeightPercent
            Kirigami.FormData.label: i18nc("@label", "Bluetooth detail height:") // qmllint disable unqualified
            from: 20; to: 60
        }

        PercentSpin {
            id: audioHeightPercent
            Kirigami.FormData.label: i18nc("@label", "Audio detail height:") // qmllint disable unqualified
            from: 24; to: 70
        }

        PercentSpin {
            id: displayHeightPercent
            Kirigami.FormData.label: i18nc("@label", "Brightness detail height:") // qmllint disable unqualified
            from: 20; to: 55
        }

        PercentSpin {
            id: powerDetailHeightPercent
            Kirigami.FormData.label: i18nc("@label", "Power detail height:") // qmllint disable unqualified
            from: 22; to: 60
        }

        PercentSpin {
            id: taskPreviewWidthPercent
            Kirigami.FormData.label: i18nc("@label", "Task preview width:") // qmllint disable unqualified
            from: 28; to: 70
        }

        PercentSpin {
            id: taskPreviewHeightPercent
            Kirigami.FormData.label: i18nc("@label", "Task preview height:") // qmllint disable unqualified
            from: 14; to: 34
        }

    }
}
