// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property alias cfg_pet: pet.currentIndex
    property alias cfg_transparent: transparent.checked
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent

    ColumnLayout {
        spacing: 10
        RowLayout {
            QQC2.Label { text: i18n("Pet:") }
            QQC2.ComboBox {
                id: pet
                model: [i18n("Cat"), i18n("Dog"), i18n("Hamster"), i18n("Robot")]
            }
        }
        Glassy.EveryStyleCards {
            Layout.fillWidth: true
            selected: pet.currentIndex
            onPicked: value => pet.currentIndex = value
            styles: ["cat", "dog", "hamster", "robo"].map((name, i) => ({
                label: [i18n("Cat"), i18n("Dog"), i18n("Hamster"), i18n("Robot")][i], value: i,
                source: Qt.resolvedUrl("../everything/EveryPet.qml"), props: {pet: name, transparent: transparent.checked}
            }))
        }
        QQC2.CheckBox {
            id: transparent
            text: i18n("On the wallpaper, without a card")
        }
        Glassy.ThemeSettings { id: theme }
    }
}
