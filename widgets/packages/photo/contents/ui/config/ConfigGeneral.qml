// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property alias cfg_imagePath: path.text
    property alias cfg_imageFillMode: fill.currentIndex
    property alias cfg_grayscaleEnabled: grey.checked
    property alias cfg_borderEnabled: border.checked
    property alias cfg_borderSize: borderSize.value
    property alias cfg_pillShapeEnabled: pill.checked
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent

    ColumnLayout {
        spacing: 10
        RowLayout {
            QQC2.Label { text: i18n("Image:") }
            QQC2.TextField { id: path; Layout.fillWidth: true }
            QQC2.Button { text: i18n("Browse…"); icon.name: "document-open"; onClicked: chooser.open() }
            QQC2.Button { text: i18n("Default"); onClicked: path.text = "default/halftone.png" }
        }
        RowLayout {
            QQC2.Label { text: i18n("Fill:") }
            QQC2.ComboBox { id: fill; model: [i18n("Crop to frame"), i18n("Fit inside"), i18n("Stretch")] }
        }
        QQC2.CheckBox { id: grey; text: i18n("Black and white") }
        QQC2.CheckBox { id: pill; text: i18n("Round frame") }
        RowLayout {
            QQC2.CheckBox { id: border; text: i18n("Border:") }
            QQC2.SpinBox { id: borderSize; enabled: border.checked; from: 1; to: 40 }
        }
        Glassy.ThemeSettings { id: theme }
    }
    FileDialog {
        id: chooser
        nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.webp *.bmp *.gif)")]
        onAccepted: path.text = selectedFile.toString().replace(/^file:\/\//, "")
    }
}
