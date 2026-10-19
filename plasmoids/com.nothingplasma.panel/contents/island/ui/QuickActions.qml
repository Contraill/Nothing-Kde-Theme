// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kcmutils as KCMUtils
import "."

// The expanded island's last row: coffee mode as a wide switch, then square
// buttons for the camera (when there is one), settings, lock, notifications
// and power.
Row {
    id: root
    spacing: 8

    signal requestNotifs
    signal requestPower
    signal requestSettings

    readonly property bool coffee: Coffee.active
    readonly property int buttonSize: 44
    readonly property int buttonCount: camera.visible ? 5 : 4

    // Coffee mode takes what the square buttons leave.
    Rectangle {
        width: root.width - (root.buttonSize + root.spacing) * root.buttonCount
        height: root.buttonSize
        radius: Theme.shapeLg
        color: root.coffee ? Theme.inverted : coffeeArea.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }

        Text {
            id: cup
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "coffee"
            color: root.coffee ? Theme.invertedFg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 20
        }
        Text {
            anchors.left: cup.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: Cfg.t("COFFEE MODE")
            color: root.coffee ? Theme.invertedFg : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.bodyMedium
            font.weight: Font.Medium
            font.letterSpacing: Theme.labelSpacing
        }
        ToggleSwitch {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            on: root.coffee
        }
        MouseArea {
            id: coffeeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Coffee.toggle()
        }
    }

    component SquareButton: Rectangle {
        id: button
        property string icon
        property bool on: false
        // Settings also answers a right click.
        property bool rightClickable: false
        signal activated
        signal rightActivated
        width: root.buttonSize
        height: root.buttonSize
        radius: Theme.shapeMd
        color: on ? Theme.inverted : area.pressed ? Theme.surfaceTop : area.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
        scale: area.pressed ? 0.98 : area.containsMouse ? 1.04 : 1.0
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Behavior on scale { NumberAnimation { duration: Theme.durShort; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasizedDecel } }
        Text {
            anchors.centerIn: parent
            text: button.icon
            color: button.on ? Theme.invertedFg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 19
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: button.rightClickable ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
            preventStealing: button.rightClickable
            onClicked: mouse => mouse.button === Qt.RightButton ? button.rightActivated() : button.activated()
        }
    }

    // USB camera access, filled while blocked; a red ring when only some cameras are.
    SquareButton {
        id: camera
        visible: ControlHub.cameraAvailable
        on: ControlHub.cameraBlocked
        opacity: ControlHub.busy ? 0.5 : 1
        icon: ControlHub.cameraBlocked ? "videocam_off" : "videocam"
        border.width: ControlHub.cameraMixed ? 1 : 0
        border.color: Theme.alert
        Accessible.role: Accessible.Button
        Accessible.name: Cfg.t("CAMERA") + " · " + Cfg.t(ControlHub.cameraBlocked ? "PRIVACY OFF" : "PRIVACY ON")
        Accessible.description: Cfg.t("CAMERA HELP")
        onActivated: ControlHub.toggleCamera()
    }
    // Island settings; a right click opens System Settings.
    SquareButton {
        icon: "settings"
        rightClickable: true
        Accessible.role: Accessible.Button
        Accessible.name: Cfg.t("ISLAND SETTINGS")
        Accessible.onPressAction: root.requestSettings()
        onActivated: root.requestSettings()
        onRightActivated: if (!Backend.preview) KCMUtils.KCMLauncher.openSystemSettings("")
    }
    SquareButton {
        icon: "lock"
        onActivated: Exec.run("qdbus6 org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.Lock")
    }
    SquareButton {
        icon: Notifs.muted ? "notifications_off" : "notifications"
        onActivated: root.requestNotifs()
    }
    SquareButton {
        icon: "power_settings_new"
        onActivated: root.requestPower()
    }
}
