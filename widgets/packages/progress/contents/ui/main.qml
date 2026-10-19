// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"
import "everything"
import "progress.js" as Progress

// How much of the year has gone, as a dot ring; or the day, week, month and
// year as dotted bars with the time left until midnight.
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

    readonly property int variant: Plasmoid.configuration.widgetVariant
    property date now: new Date()
    readonly property var spans: Progress.spans(now, Qt.locale().firstDayOfWeek % 7)
    readonly property int minutesLeft: Progress.minutesToMidnight(now)

    // EveryThing-UI's year (2, 3) and countdown (4, 5), each as a block then a circle.
    readonly property bool every: variant >= 2
    readonly property bool countdown: variant >= 4

    // Wakes on the minute so the numbers turn over with the clock; the
    // countdown block shows seconds, so it ticks every second.
    Timer {
        running: true
        repeat: true
        interval: root.variant === 4 ? 1000 : 60000 - root.now.getSeconds() * 1000
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 200
        Layout.preferredHeight: 200
        Layout.minimumWidth: 150
        Layout.minimumHeight: 150

        EveryProgress {
            anchors.fill: parent
            visible: root.every
            colors: nColors
            family: dotFont.name
            kind: root.countdown ? "countdown" : "year"
            round: root.variant === 3 || root.variant === 5
            now: root.now
            yearFraction: root.spans.year
            dayFraction: root.spans.day
            dayOfYear: Progress.dayOfYear(root.now)
        }

        Glassy.GlassySurface {
            id: card
            visible: !root.every
            anchors.fill: parent
            anchors.margins: 10
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }

        // 0: the year as a ring.
        Item {
            anchors.fill: card
            anchors.margins: 16
            visible: root.variant === 0
            Glassy.DotRing {
                id: ring
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                count: 40
                value: root.spans.year
                litColor: nColors.accent
                dimColor: nColors.divider
            }
            Column {
                anchors.centerIn: ring
                spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(root.spans.year * 100) + "%"
                    font.family: dotFont.name
                    font.pixelSize: ring.width * 0.2
                    color: nColors.textPrimary
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n("DAY %1", Progress.dayOfYear(root.now))
                    font.pixelSize: Math.max(9, ring.width * 0.065)
                    font.letterSpacing: 1.5
                    color: nColors.textSecondary
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.now.getFullYear()
                    font.family: dotFont.name
                    font.pixelSize: Math.max(10, ring.width * 0.08)
                    color: nColors.textSecondary
                }
            }
        }

        // 1: day, week, month and year as bars.
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 16
            visible: root.variant === 1
            spacing: 6
            Glassy.DotMeter { colors: nColors; Layout.fillWidth: true; label: i18n("DAY"); percent: root.spans.day * 100 }
            Glassy.DotMeter { colors: nColors; Layout.fillWidth: true; label: i18n("WEEK"); percent: root.spans.week * 100 }
            Glassy.DotMeter { colors: nColors; Layout.fillWidth: true; label: i18n("MONTH"); percent: root.spans.month * 100 }
            Glassy.DotMeter { colors: nColors; Layout.fillWidth: true; label: i18n("YEAR"); percent: root.spans.year * 100 }
            Item { Layout.fillHeight: true }
            Text {
                Layout.fillWidth: true
                text: i18n("%1 h %2 min until midnight", Math.floor(root.minutesLeft / 60), root.minutesLeft % 60)
                font.pixelSize: 11
                elide: Text.ElideRight
                color: nColors.textSecondary
            }
        }
    }
}
