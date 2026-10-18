// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"

// A sticky note; the text is kept in the widget's own configuration.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }
    Glassy.DotFont { id: dotFont }

    fullRepresentation: Item {
        Layout.preferredWidth: 240
        Layout.preferredHeight: 220
        Layout.minimumWidth: 160
        Layout.minimumHeight: 140

        Glassy.GlassySurface {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 14
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: i18n("NOTE")
                    font.family: dotFont.name
                    font.pixelSize: 20
                    color: nColors.accent
                }
                Item { Layout.fillWidth: true }
                Text {
                    // Saving shows briefly, like a status dot.
                    text: "•"
                    font.pixelSize: 16
                    color: nColors.accent
                    opacity: save.running ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                QQC2.TextArea {
                    id: editor
                    text: Plasmoid.configuration.noteText
                    placeholderText: i18n("Write something…")
                    placeholderTextColor: nColors.textMuted
                    color: nColors.textPrimary
                    selectionColor: nColors.accent
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    font.pixelSize: 15
                    background: null
                    leftPadding: 0
                    rightPadding: 0
                    onTextChanged: if (text !== Plasmoid.configuration.noteText) save.restart()
                }
            }
        }
        // Writes after a pause in typing rather than on every key.
        Timer {
            id: save
            interval: 700
            onTriggered: Plasmoid.configuration.noteText = editor.text
        }
        // A pending save must not be lost when Plasma quits mid-pause.
        Component.onDestruction: if (save.running) Plasmoid.configuration.noteText = editor.text
    }
}
