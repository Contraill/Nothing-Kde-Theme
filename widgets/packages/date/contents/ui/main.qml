// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"

// The date three ways: a page that turns to the month, a month of dots, or
// a pill with the month's progress as a ring.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }
    Glassy.SerifFont { id: serif }
    Glassy.SerifFont { id: serifLight; light: true }
    Glassy.DotFont { id: dots }

    readonly property int variant: Plasmoid.configuration.widgetVariant
    readonly property var locale: Qt.locale()
    property date today: new Date()
    // Recheck shortly after midnight rather than every second.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: if (new Date().getDate() !== root.today.getDate()) root.today = new Date()
    }
    readonly property int daysInMonth: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

    function upper(text) { return text.toLocaleUpperCase(locale.name); }

    fullRepresentation: Item {
        Layout.preferredWidth: root.variant === 2 ? 240 : 200
        Layout.preferredHeight: root.variant === 2 ? 100 : 200
        Layout.minimumWidth: root.variant === 2 ? 180 : 150
        Layout.minimumHeight: root.variant === 2 ? 80 : 150

        Glassy.GlassySurface {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: root.variant === 2 ? height / 2 : 20
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }

        // 0: the day, then the month on the back.
        DatePage {
            anchors.fill: card
            visible: root.variant === 0
            colors: nColors
            today: root.today
            locale: root.locale
            numberFamily: serif.name
            labelFamily: serifLight.name
        }

        // 1: this month as dots, today in the accent.
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 14
            visible: root.variant === 1
            spacing: 8
            Text {
                text: root.upper(root.locale.standaloneMonthName(root.today.getMonth(), Locale.LongFormat))
                color: nColors.textPrimary
                font.family: dots.name
                font.pixelSize: Math.max(14, card.height * 0.09)
            }
            MonthGrid {
                Layout.alignment: Qt.AlignHCenter
                colors: nColors
                today: root.today
                locale: root.locale
                numbers: false
                cell: Math.min((card.width - 28) / 7, (card.height - 50) / 6)
            }
        }

        // 2: a pill, the month's progress around the date.
        RowLayout {
            anchors.fill: card
            anchors.leftMargin: 14
            anchors.rightMargin: 20
            visible: root.variant === 2
            spacing: 12
            Item {
                Layout.preferredWidth: card.height - 26
                Layout.preferredHeight: card.height - 26
                Glassy.DotRing {
                    anchors.fill: parent
                    count: root.daysInMonth
                    value: root.today.getDate() / root.daysInMonth
                    litColor: nColors.accent
                    dimColor: nColors.divider
                }
                Text {
                    anchors.centerIn: parent
                    text: root.today.getDate()
                    color: nColors.textPrimary
                    font.family: dots.name
                    font.pixelSize: parent.height * 0.36
                }
            }
            Column {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    width: parent.width
                    text: root.upper(root.locale.standaloneMonthName(root.today.getMonth(), Locale.LongFormat))
                    color: nColors.textPrimary
                    font.family: dots.name
                    font.pixelSize: Math.max(15, card.height * 0.2)
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.upper(root.locale.dayName(root.today.getDay(), Locale.LongFormat))
                    color: nColors.accent
                    font.pixelSize: Math.max(11, card.height * 0.12)
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                }
            }
        }
    }
}
