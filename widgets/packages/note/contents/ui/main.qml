// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"
import "everything"

// A sticky note, or its first line as a mantra pill; the text is kept in
// the widget's own configuration.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
        monochrome: Plasmoid.configuration.monochrome
    }
    Glassy.DotFont { id: dotFont }
    readonly property bool pill: Plasmoid.configuration.widgetVariant === 1
    // 2: EveryThing-UI's mantra, cycling through the note's lines.
    readonly property bool mantra: Plasmoid.configuration.widgetVariant === 2
    readonly property var phrases: {
        const lines = Plasmoid.configuration.noteText.split("\n").map(l => l.trim()).filter(l => l.length);
        return lines.length ? lines : [i18n("Stay focused"), i18n("Keep going"), i18n("You got this"), i18n("Embrace the void"), i18n("Nothing to fear")];
    }

    fullRepresentation: Item {
        Layout.preferredWidth: root.mantra ? 400 : root.pill ? 260 : 240
        Layout.preferredHeight: root.mantra ? 115 : root.pill ? 64 : 220
        Layout.minimumWidth: 160
        Layout.minimumHeight: root.pill || root.mantra ? 52 : 140

        EveryMantra {
            anchors.fill: parent
            visible: root.mantra
            colors: nColors
            family: dotFont.name
            phrases: root.phrases
        }

        Glassy.GlassySurface {
            id: card
            visible: !root.mantra
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: root.pill ? height / 2 : 20
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 14
            spacing: 6
            visible: !root.pill && !root.mantra
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
        // The pill edits the first line; the rest of the note is kept.
        RowLayout {
            anchors.fill: card
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            visible: root.pill
            spacing: 10
            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: nColors.accent
            }
            TextInput {
                id: mantra
                Layout.fillWidth: true
                readonly property string rest: editor.text.indexOf("\n") < 0 ? "" : editor.text.slice(editor.text.indexOf("\n"))
                text: editor.text.split("\n")[0]
                color: nColors.textPrimary
                selectionColor: nColors.accent
                selectByMouse: true
                clip: true
                font.pixelSize: 14
                font.letterSpacing: 1.5
                font.capitalization: Font.AllUppercase
                onTextEdited: editor.text = text + rest
                Text {
                    visible: !mantra.text && !mantra.activeFocus
                    text: i18n("Write a mantra…")
                    font: mantra.font
                    color: nColors.textMuted
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
