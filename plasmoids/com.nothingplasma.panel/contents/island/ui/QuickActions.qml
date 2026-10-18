import QtQuick
import org.kde.kcmutils as KCMUtils
import "."
Row {
    id: root
    spacing: 8

    readonly property bool coffee: Coffee.active
    signal requestNotifs
    signal requestPower
    signal requestSettings

    readonly property int btnSize: 44
    readonly property int botones: 4
    Rectangle {
        width: root.width - (root.btnSize + root.spacing) * root.botones
        height: 44
        radius: Theme.shapeLg
        color: root.coffee ? Theme.inverted : coffeeMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation {
                duration: Theme.durMedium
            }
        }

        Text {
            id: coffeeIcon
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "coffee"
            color: root.coffee ? Theme.invertedFg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 20
        }

        Text {
            anchors.left: coffeeIcon.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: Cfg.t("COFFEE MODE")
            color: root.coffee ? Theme.invertedFg : Theme.fg
            font.letterSpacing: Theme.labelSpacing
            font.family: Theme.font
            font.pixelSize: Theme.bodyMedium
            font.weight: Font.Medium
        }
        Rectangle {
            id: track
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 24
            radius: height / 2
            color: root.coffee ? Theme.invertedFg : Theme.surfaceHigh
            border.width: root.coffee ? 0 : 2
            border.color: Theme.outline

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durMedium
                }
            }

            Rectangle {
                width: root.coffee ? 18 : 14
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.coffee ? parent.width - width - 3 : 4
                color: root.coffee ? Theme.inverted : Theme.fgFaint

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durShort
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }
            }
        }

        MouseArea {
            id: coffeeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Coffee.toggle();
            }
        }
    }

    component ActionButton: Rectangle {
        id: ab
        property string icon: ""
        property bool danger: false
        property bool rightClickable: false
        signal activated
        signal rightActivated

        width: root.btnSize
        height: 44
        radius: Theme.shapeMd
        color: abMa.pressed ? Theme.surfaceTop : abMa.containsMouse ? Theme.surfaceHigh : Theme.containerHigh
        scale: abMa.pressed ? 0.98 : abMa.containsMouse ? 1.04 : 1.0

        Behavior on color {
            ColorAnimation {
                duration: Theme.durShort
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.durShort
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.emphasizedDecel
            }
        }

        Text {
            anchors.centerIn: parent
            text: ab.icon
            color: ab.danger ? Theme.error : Theme.fgVariant
            font.family: Theme.fontIcons
            font.pixelSize: 19
        }

        MouseArea {
            id: abMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: ab.rightClickable ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
            preventStealing: ab.rightClickable
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) ab.rightActivated();
                else ab.activated();
            }
        }
    }

    ActionButton {
        icon: "settings"
        rightClickable: true
        Accessible.role: Accessible.Button
        Accessible.name: Cfg.t("ISLAND SETTINGS")
        Accessible.onPressAction: root.requestSettings()
        onActivated: root.requestSettings()
        onRightActivated: if (!Backend.preview) KCMUtils.KCMLauncher.openSystemSettings("")
    }

    ActionButton {
        icon: "lock"
        onActivated: Exec.run("qdbus6 org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.Lock")
    }

    ActionButton {
        icon: Notifs.muted ? "notifications_off" : "notifications"
        onActivated: root.requestNotifs()
    }

    ActionButton {
        icon: "power_settings_new"
        onActivated: root.requestPower()
    }

}
