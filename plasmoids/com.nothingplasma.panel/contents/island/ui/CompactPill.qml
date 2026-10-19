// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// The closed island: workspaces, weather, phone and live activities on the
// left; the clock (or a volume OSD) in the middle; network and volume, or
// the mini player while something plays, then the tray and battery on the
// right.
Item {
    id: root

    // The panel parents its system tray into traySlot and tells us its width.
    property real trayWidth: 0
    readonly property alias traySlot: traySlot
    signal weatherSettingsRequested()

    implicitWidth: Theme.collapsedWidth
    implicitHeight: Theme.collapsedHeight

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: Math.min(parent.height, Theme.collapsedHeight)
        radius: height / 2
        color: Theme.surface
        clip: true

        Row {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
                visible: Cfg.showWorkspaces
            }
            WeatherWidget {
                anchors.verticalCenter: parent.verticalCenter
                visible: Cfg.showWeather
                onConfigureRequested: root.weatherSettingsRequested()
            }
            // KDE Connect is optional: without its module only this indicator is missing.
            Loader {
                anchors.verticalCenter: parent.verticalCenter
                active: Cfg.showPhone
                source: "PhoneBattery.qml"
                visible: status === Loader.Ready
            }
            ActivityChips {
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // The OSD takes the clock's place while it shows.
        Clock {
            anchors.centerIn: parent
            visible: Cfg.showClock
            opacity: osd.shown ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
        }
        IslandOsd {
            id: osd
            anchors.centerIn: parent
        }

        // The battery stays at the edge whatever else comes and goes.
        Battery {
            id: persistentBattery
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            visible: Cfg.showBattery && present
        }
        Item {
            id: traySlot
            anchors.right: persistentBattery.visible ? persistentBattery.left : parent.right
            anchors.rightMargin: persistentBattery.visible ? 10 : 16
            anchors.verticalCenter: parent.verticalCenter
            width: root.trayWidth
            height: 28
        }
        // Network and volume give way to the mini player; scrolling here sets the volume.
        Item {
            id: statusGroup
            anchors.right: traySlot.left
            anchors.rightMargin: root.trayWidth > 0 ? 10 : 0
            anchors.verticalCenter: parent.verticalCenter
            width: player.active ? player.implicitWidth : indicators.width
            height: Math.max(indicators.height, player.implicitHeight)
            Behavior on width { NumberAnimation { duration: Theme.durLong; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasizedDecel } }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                acceptedButtons: Qt.NoButton
                onWheel: wheel => Audio.wheel(wheel)
            }
            Row {
                id: indicators
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                opacity: player.active ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
                Network {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Cfg.showNetwork
                }
                Volume {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Cfg.showVolume
                }
            }
            MiniPlayer {
                id: player
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                opacity: active ? 1 : 0
                scale: active ? 1 : 0.72
                transformOrigin: Item.Right
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
                Behavior on scale { SpringAnimation { spring: 9.0; damping: 0.5; mass: 0.35; epsilon: 0.005 } }
            }
        }
    }
}
