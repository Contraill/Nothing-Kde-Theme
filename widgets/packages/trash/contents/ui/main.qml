// SPDX-License-Identifier: GPL-3.0-or-later
import QtCore
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "../../../../shared" as Glassy
import "components"

// The trash: how many items it holds and their size; click to open it.
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

    // shortcut: only the home trash is counted, not trash folders on other drives; use KIO's trash:/ listing if that matters.
    FolderListModel {
        id: items
        folder: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/Trash/info"
        nameFilters: ["*.trashinfo"]
        showDirs: false
        showHidden: true
        onCountChanged: measure.restart()
    }
    property real bytes: 0

    // du reads the size; the path comes from the environment, never from text.
    readonly property string sizeCommand: 'du -sb -- "${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files" 2>/dev/null'
    P5Support.DataSource {
        id: shell
        engine: "executable"
        onNewData: (source, data) => {
            root.bytes = parseInt(data.stdout) || 0;
            disconnectSource(source);
        }
    }
    // Bursts of deletions settle before measuring.
    Timer {
        id: measure
        interval: 800
        onTriggered: shell.connectSource(root.sizeCommand)
    }
    Component.onCompleted: measure.restart()

    fullRepresentation: Item {
        Layout.preferredWidth: 160
        Layout.preferredHeight: 160
        Layout.minimumWidth: 120
        Layout.minimumHeight: 120

        Glassy.GlassySurface {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }
        MouseArea {
            id: area
            anchors.fill: card
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally("trash:/")
            Accessible.role: Accessible.Button
            Accessible.name: i18n("Open the trash")
        }
        ColumnLayout {
            anchors.centerIn: card
            spacing: 4
            Glassy.DotGlyph {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: card.height * 0.16
                Layout.preferredHeight: card.height * 0.2
                visible: items.count === 0
                name: "trash"
                color: nColors.textMuted
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: items.count > 0
                text: items.count
                font.family: dotFont.name
                font.pixelSize: card.height * 0.28
                color: nColors.textPrimary
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("TRASH")
                font.pixelSize: 11
                font.letterSpacing: 1.5
                color: nColors.textSecondary
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: items.count > 0 ? Qt.locale().formattedDataSize(root.bytes, 1) : i18n("Empty")
                font.family: dotFont.name
                font.pixelSize: 12
                color: items.count > 0 ? nColors.accent : nColors.textMuted
            }
        }
        scale: area.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }
    }
}
