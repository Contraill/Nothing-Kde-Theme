import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import "components"
import "everything"
import "../../../../shared" as Glassy

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }

    preferredRepresentation: fullRepresentation

    property int fontStyle: Plasmoid.configuration.fontStyle
    property bool showDate: Plasmoid.configuration.showDate
    property bool use24HourFormat: Plasmoid.configuration.use24HourFormat
    property bool useDarkerFont: Plasmoid.configuration.useDarkerFont

    // Current date and time properties
    property string currentDate: ""
    property string currentTime: ""

    // Font loaders for the three variants
    FontLoader {
        id: dottedFont
        source: Qt.resolvedUrl("../fonts/close_dotted.ttf")
    }

    // The light build: at this size the regular dots would touch.
    Glassy.DotFont {
        id: dotMatrixFont
        light: true
    }

    FontLoader {
        id: serifFont
        source: Qt.resolvedUrl("../fonts/serif.otf")
    }

    FontLoader {
        id: arrowSubwayFont
        source: Qt.resolvedUrl("../fonts/arrow_subway.ttf")
    }

    FontLoader {
        id: arrowSharpFont
        source: Qt.resolvedUrl("../fonts/arrow_shape_f.ttf")
    }

    // Faces for EveryThing-UI's clocks (fontStyle 5 to 10).
    Glassy.DotFont { id: everyDots; light: true }
    Glassy.GroteskFont { id: everyOutline }
    property string everyTime: "00:00"
    readonly property bool everyStyle: fontStyle >= 5

    FontLoader {
        id: robotoFont
        source: Qt.resolvedUrl("../fonts/roboto.ttf")
    }

    // Timer to update time
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateDateTime()
        Component.onCompleted: updateDateTime()
    }

    function updateDateTime() {
        var now = new Date()
        root.everyTime = Qt.formatTime(now, root.use24HourFormat ? "HH:mm" : "hh:mm")
        root.currentDate = Qt.locale().toString(now, "ddd, dd MMM")

        // Arrow Subway font (fontStyle 3) uses format without separator
        if (root.fontStyle === 3 || root.fontStyle == 4) {
            var hours = now.getHours()
            var minutes = now.getMinutes()

            // Handle 12-hour format for segmented fonts
            if (!root.use24HourFormat) {
                hours = hours % 12
                if (hours === 0) hours = 12
            }

            var minutesStr = minutes < 10 ? "0" + minutes : minutes.toString()
            root.currentTime = hours.toString() + minutesStr
        } else {
            // Use appropriate format string based on setting
            var timeFormat = root.use24HourFormat ? "H:mm" : "h:mm AP"
            root.currentTime = Qt.formatTime(now, timeFormat)
        }
    }



    fullRepresentation: Item {
        Layout.preferredWidth: 400
        Layout.preferredHeight: root.showDate ? 200 : 180
        Layout.minimumWidth: 300
        Layout.minimumHeight: root.showDate ? 200 : 150
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0

            // Date display (optional)
            Text {
                id: dateLabel
                Layout.alignment: Qt.AlignHCenter
                visible: root.showDate
                text: root.currentDate
                font.family: robotoFont.name
                font.bold: true
                font.weight: Font.Bold
                color: nColors.textPrimary
                opacity: 0.9
                // Reserve the existing date row independently of its font metrics.
                // Reading height here feeds the layout result back into font.pixelSize.
                Layout.preferredHeight: 10

                font.pixelSize: {
                    var availableHeight = parent.height - (root.showDate ? dateLabel.Layout.preferredHeight : 0)
                    var availableWidth = parent.width - 40

                    return Math.min(availableHeight * 0.1, availableWidth * 0.1)

                }

                Layout.topMargin: 0
                Layout.bottomMargin: 0
            }

            EveryBigClock {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.everyStyle
                colors: nColors
                face: ["blocks", "blocks-dual", "dots", "bubbles", "bubbles-inverse", "outline"][root.fontStyle - 5] ?? "blocks"
                time: root.everyTime
                dotFamily: everyDots.name
                outlineFamily: everyOutline.name
            }

            // Time display
            Text {
                id: timeLabel
                visible: !root.everyStyle
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.fillHeight: false
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.topMargin: -30

                text: root.currentTime
                color: nColors.textPrimary

                // Font selection based on style
                font.family: {
                    switch (root.fontStyle) {
                        case 0: return dottedFont.name
                        case 1: return dotMatrixFont.name
                        case 2: return serifFont.name
                        case 3: return arrowSubwayFont.name
                        case 4: return arrowSharpFont.name
                        default: return dottedFont.name
                    }
                }

                // Adjust font size based on available space
                font.pixelSize: {
                    var availableHeight = parent.height - (root.showDate ? dateLabel.Layout.preferredHeight : 0)
                    var availableWidth = parent.width - 40

                    // Calculate optimal size based on text width
                    // Dotted and dot matrix fonts need more space
                    if (root.fontStyle === 0 || root.fontStyle === 1) {
                        return Math.min(availableHeight * 0.6, availableWidth / 3.5)
                    } else if (root.fontStyle === 3) {
                        // Arrow Subway font needs more space (no colon separator)
                        return Math.min(availableHeight * 0.6, availableWidth / 4.0)
                    } else {
                        // Serif font is more compact
                        return Math.min(availableHeight * 0.7, availableWidth / 2.5)
                    }
                }

                // Letter spacing for better readability
                font.letterSpacing: {
                    if (root.fontStyle === 2) {
                        return 8  // Tighter spacing for serif
                    } else if (root.fontStyle === 3 || root.fontStyle == 4) {
                        return 0  // Negative spacing for arrow subway to make numbers touch
                    } else {
                        return 12  // More spacing for dotted/matrix fonts
                    }
                }

                style: Text.Normal
                styleColor: "transparent"
            }

        }
    }
}
