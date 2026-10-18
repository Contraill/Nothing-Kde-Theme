// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"

// An analog clock: classic ticks, a minimal face, or a ring of hour dots.
// The second hand is the accent.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }

    readonly property int variant: Plasmoid.configuration.widgetVariant
    readonly property bool smooth: Plasmoid.configuration.smoothHands
    property date now: new Date()
    Timer {
        interval: root.smooth ? 50 : 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
    readonly property real seconds: now.getSeconds() + (smooth ? now.getMilliseconds() / 1000 : 0)
    readonly property real minutes: now.getMinutes() + seconds / 60
    readonly property real hours: now.getHours() % 12 + minutes / 60

    // A hand pivoting at the dial's centre; `overhang` reaches past it.
    component Hand: Rectangle {
        id: hand
        required property real angle
        required property real length
        property real overhang: 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - length
        height: length + overhang
        radius: width / 2
        antialiasing: true
        transform: Rotation {
            origin.x: hand.width / 2
            origin.y: hand.length
            angle: hand.angle
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 200
        Layout.preferredHeight: 200
        Layout.minimumWidth: 120
        Layout.minimumHeight: 120

        Glassy.VariantPicker {
            anchors.fill: parent
            visible: root.variant < 0
            colors: nColors
            variants: [i18n("Classic"), i18n("Minimal"), i18n("Dots")]
            onChosen: index => Plasmoid.configuration.widgetVariant = index
        }

        Item {
            id: dial
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) - 20
            height: width
            visible: root.variant >= 0
            readonly property real r: width / 2

            Glassy.GlassySurface {
                anchors.fill: parent
                cornerRadius: width / 2
                backgroundColor: nColors.background
                foregroundColor: nColors.textPrimary
            }
            // Classic: 60 ticks, the hours longer.
            Repeater {
                model: root.variant === 0 ? 60 : 0
                Rectangle {
                    required property int index
                    readonly property bool hour: index % 5 === 0
                    width: hour ? dial.r * 0.035 : dial.r * 0.018
                    height: hour ? dial.r * 0.12 : dial.r * 0.05
                    radius: width / 2
                    x: dial.r - width / 2
                    y: dial.r * 0.1
                    color: hour ? nColors.textPrimary : nColors.textMuted
                    transform: Rotation { origin.x: width / 2; origin.y: dial.r * 0.9; angle: index * 6 }
                }
            }
            // Dots: twelve hour dots, the passed ones lit.
            Repeater {
                model: root.variant === 2 ? 12 : 0
                Rectangle {
                    required property int index
                    readonly property real angle: index * Math.PI / 6 - Math.PI / 2
                    width: dial.r * (index % 3 === 0 ? 0.11 : 0.08)
                    height: width
                    radius: width / 2
                    x: dial.r + dial.r * 0.8 * Math.cos(angle) - width / 2
                    y: dial.r + dial.r * 0.8 * Math.sin(angle) - height / 2
                    color: index <= Math.floor(root.hours) ? nColors.textPrimary : nColors.alpha(nColors.textPrimary, 0.2)
                }
            }
            Hand {
                angle: root.hours * 30
                length: dial.r * (root.variant === 1 ? 0.5 : 0.5)
                width: dial.r * (root.variant === 1 ? 0.12 : 0.06)
                color: root.variant === 1 ? nColors.textSecondary : nColors.textPrimary
            }
            Hand {
                angle: root.minutes * 6
                length: dial.r * (root.variant === 2 ? 0.62 : 0.74)
                width: dial.r * (root.variant === 1 ? 0.05 : 0.04)
                color: nColors.textPrimary
            }
            // Seconds: a thin accent hand, or on the minimal face a dot on the rim.
            Hand {
                visible: root.variant !== 1
                angle: root.seconds * 6
                length: dial.r * 0.8
                overhang: dial.r * 0.16
                width: Math.max(1.5, dial.r * 0.014)
                color: nColors.accentSecondHand
            }
            Rectangle {
                visible: root.variant === 1
                readonly property real angle: root.seconds * Math.PI / 30 - Math.PI / 2
                width: dial.r * 0.07
                height: width
                radius: width / 2
                x: dial.r + dial.r * 0.86 * Math.cos(angle) - width / 2
                y: dial.r + dial.r * 0.86 * Math.sin(angle) - height / 2
                color: nColors.accentSecondHand
            }
            Rectangle {
                anchors.centerIn: parent
                width: dial.r * 0.08
                height: width
                radius: width / 2
                color: root.variant === 1 ? nColors.textPrimary : nColors.accentSecondHand
            }
        }
    }
}
