import QtQuick
import "."
Item {
    id: root

    signal weatherSettingsRequested()
    implicitWidth: Theme.collapsedWidth
    implicitHeight: Theme.collapsedHeight
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Math.min(parent.height, Theme.collapsedHeight)
        radius: height / 2
        color: Theme.surface
        clip: true

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
                visible: Cfg.showWorkspaces
            }

            WeatherWidget {
                onConfigureRequested: root.weatherSettingsRequested()
                anchors.verticalCenter: parent.verticalCenter
                visible: Cfg.showWeather
            }
        }

        Clock {
            anchors.centerIn: parent
            visible: Cfg.showClock
        }
        Battery {
            id: persistentBattery
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            visible: Cfg.showBattery && present
        }
        Item {
            id: rightGroup
            anchors.right: persistentBattery.visible ? persistentBattery.left : parent.right
            anchors.rightMargin: persistentBattery.visible ? 10 : 16
            anchors.verticalCenter: parent.verticalCenter
            width: mini.active ? mini.implicitWidth : rightRow.width
            height: Math.max(rightRow.height, mini.implicitHeight)

            Behavior on width {
                NumberAnimation {
                    duration: Theme.durLong
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.emphasizedDecel
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                acceptedButtons: Qt.NoButton
                onWheel: wheel => Audio.step(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
            }

            Row {
                id: rightRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                opacity: mini.active ? 0 : 1
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durShort
                    }
                }

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
                id: mini
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                opacity: active ? 1 : 0
                scale: active ? 1 : 0.72
                transformOrigin: Item.Right
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durMedium
                    }
                }
                Behavior on scale {
                    SpringAnimation {
                        spring: 9.0
                        damping: 0.5
                        mass: 0.35
                        epsilon: 0.005
                    }
                }
            }
        }
    }
}
