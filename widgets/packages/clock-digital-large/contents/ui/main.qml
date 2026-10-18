// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"

// A large clock straight on the wallpaper, in one of four faces; the text
// fits whatever size the widget is given.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }
    Glassy.DotFont { id: dots; light: true }
    Glassy.SerifFont { id: serif }
    Glassy.GroteskFont { id: grotesk }

    readonly property var config: Plasmoid.configuration
    // Older versions had five faces; the retired ones fall back to dots.
    readonly property int face: config.fontStyle >= 0 && config.fontStyle <= 3 ? config.fontStyle : 0
    readonly property string family: [dots.name, dots.name, serif.name, grotesk.name][face]
    readonly property color ink: config.useDarkerFont ? nColors.textSecondary : nColors.textPrimary
    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
    // Qt's "h" is only 12-hour next to an AM/PM marker, so count it here.
    readonly property string hours: config.use24HourFormat ? Qt.locale().toString(now, "HH") : String((now.getHours() + 11) % 12 + 1)
    readonly property string minutes: Qt.locale().toString(now, "mm")
    readonly property string meridiem: config.use24HourFormat ? "" : (now.getHours() < 12 ? Qt.locale().amText : Qt.locale().pmText)

    fullRepresentation: Item {
        id: frame
        Layout.preferredWidth: 320
        Layout.preferredHeight: 160
        Layout.minimumWidth: 140
        Layout.minimumHeight: 70

        Glassy.GlassySurface {
            anchors.fill: parent
            anchors.margins: 10
            visible: root.config.showBackground
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.config.showBackground ? 22 : 6
            spacing: 0
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root.config.showDate || root.meridiem !== ""
                // AM/PM rides on the date line rather than shrinking the time.
                text: (root.config.showDate ? Qt.locale().toString(root.now, "ddd, d MMM") : "") + (root.config.showDate && root.meridiem ? " · " : "") + root.meridiem
                color: nColors.textSecondary
                font.family: grotesk.name
                font.pixelSize: Math.max(11, frame.height * 0.11)
            }
            Text {
                id: time
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 12
                font.pixelSize: 400
                font.family: root.family
                font.weight: root.face === 3 ? Font.Medium : Font.Normal
                textFormat: Text.StyledText
                // The two-tone face paints the minutes in the accent.
                text: {
                    const minutes = root.face === 1 ? "<font color=\"" + nColors.accent + "\">" + root.minutes + "</font>" : root.minutes;
                    return root.hours + ":" + minutes;
                }
                color: root.ink
            }
        }
    }
}
