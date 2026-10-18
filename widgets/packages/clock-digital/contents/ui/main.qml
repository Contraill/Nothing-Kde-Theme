// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "../../../../shared" as Glassy
import "components"

// Dot-matrix time: hours over minutes, a pill, or another city's time.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }
    Glassy.DotFont { id: dots }
    Glassy.DotFont { id: bigDots; light: true }

    readonly property var config: Plasmoid.configuration
    readonly property int variant: config.widgetVariant
    readonly property bool world: variant === 1
    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // Plasma's own time engine knows each zone's offset, daylight saving included.
    P5Support.DataSource {
        id: zone
        engine: "time"
        connectedSources: root.world ? [root.config.timeZone] : []
        interval: 60000
    }
    readonly property int zoneOffset: zone.data[config.timeZone]?.["Offset"] ?? 0
    readonly property int localOffset: -now.getTimezoneOffset() * 60
    readonly property date shown: world ? new Date(now.getTime() + (zoneOffset - localOffset) * 1000) : now
    // Qt's "h" is only 12-hour next to an AM/PM marker, so count it here.
    readonly property string hours: config.use24HourFormat ? Qt.locale().toString(shown, "HH") : String((shown.getHours() + 11) % 12 + 1).padStart(2, "0")
    readonly property string minutes: Qt.locale().toString(shown, "mm")
    readonly property string meridiem: config.use24HourFormat ? "" : (shown.getHours() < 12 ? Qt.locale().amText : Qt.locale().pmText)
    // "+3 H" ahead of the local time, as a whole or half hour.
    readonly property string difference: {
        const hours = (zoneOffset - localOffset) / 3600;
        return (hours > 0 ? "+" : hours < 0 ? "−" : "±") + Qt.locale().toString(Math.abs(hours), "f", hours % 1 ? 1 : 0) + " " + i18n("H");
    }
    function upper(text) { return text.toLocaleUpperCase(Qt.locale().name); }

    fullRepresentation: Item {
        Layout.preferredWidth: root.variant === 2 ? 260 : 200
        Layout.preferredHeight: root.variant === 2 ? 100 : 200
        Layout.minimumWidth: root.variant === 2 ? 180 : 140
        Layout.minimumHeight: root.variant === 2 ? 70 : 140

        Glassy.VariantPicker {
            anchors.fill: parent
            visible: root.variant < 0
            colors: nColors
            variants: [i18n("Hours over minutes"), i18n("World clock"), i18n("Pill")]
            onChosen: index => Plasmoid.configuration.widgetVariant = index
        }
        Glassy.GlassySurface {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            visible: root.variant >= 0
            cornerRadius: root.variant === 2 ? height / 2 : 20
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }

        // 0: hours over minutes with a ticking pair of accent dots.
        Column {
            anchors.centerIn: card
            visible: root.variant === 0
            spacing: card.height * 0.02
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.hours
                color: nColors.textPrimary
                font.family: bigDots.name
                font.pixelSize: card.height * 0.36
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: card.height * 0.05
                Repeater {
                    model: 2
                    Rectangle {
                        width: card.height * 0.035
                        height: width
                        radius: width / 2
                        color: nColors.accent
                        opacity: root.now.getSeconds() % 2 ? 0.25 : 1
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.minutes
                color: nColors.textPrimary
                font.family: bigDots.name
                font.pixelSize: card.height * 0.36
            }
        }

        // 1: another city, its weekday and the difference to local time.
        Item {
            anchors.fill: card
            anchors.margins: 14
            visible: root.world
            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                width: parent.width
                text: root.upper(root.config.cityName)
                color: nColors.accent
                font.family: dots.name
                font.pixelSize: parent.height * 0.13
                elide: Text.ElideRight
            }
            Text {
                anchors.centerIn: parent
                text: root.hours + ":" + root.minutes
                color: nColors.textPrimary
                font.family: bigDots.name
                font.pixelSize: Math.min(parent.height * 0.34, parent.width * 0.3)
            }
            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                text: root.upper(Qt.locale().standaloneDayName(root.shown.getDay(), Locale.LongFormat)) + (root.meridiem ? " · " + root.meridiem : "")
                color: nColors.textSecondary
                font.pixelSize: parent.height * 0.08
                font.letterSpacing: 1.2
            }
            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: root.difference
                color: nColors.textSecondary
                font.family: dots.name
                font.pixelSize: parent.height * 0.1
            }
        }

        // 2: a pill, the colon in the accent.
        Text {
            anchors.centerIn: card
            visible: root.variant === 2
            textFormat: Text.StyledText
            text: root.hours + "<font color=\"" + nColors.accent + "\">:</font>" + root.minutes
                + (root.meridiem ? " <font color=\"" + nColors.textSecondary + "\">" + root.meridiem + "</font>" : "")
            color: nColors.textPrimary
            font.family: bigDots.name
            font.pixelSize: card.height * 0.5
        }
    }
}
