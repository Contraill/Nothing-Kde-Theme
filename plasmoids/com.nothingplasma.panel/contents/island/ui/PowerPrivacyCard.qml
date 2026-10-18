import QtQuick
import QtQuick.Controls as QQC2
import "."

Rectangle {
    id: root
    radius: Theme.shapeLg
    color: Theme.surfaceAlt

    Row {
        x: 8; y: 8
        width: parent.width - 16
        height: 42
        spacing: 2
        Repeater {
            model: [
                {value: "power-saver", title: "POWER SAVER", icon: "eco"},
                {value: "balanced", title: "BALANCED", icon: "balance"},
                {value: "performance", title: "PERFORMANCE", icon: "bolt"}
            ]
            QQC2.AbstractButton {
                id: option
                required property var modelData
                width: (parent.width - 4) / 3
                height: 42
                enabled: !ControlHub.busy && ControlHub.profiles.includes(modelData.value)
                checked: ControlHub.profile === modelData.value
                Accessible.name: Cfg.t(modelData.title)
                Accessible.description: enabled ? "" : Cfg.t("UNAVAILABLE")
                onClicked: ControlHub.setProfile(modelData.value)
                background: Rectangle {
                    radius: 11
                    color: option.checked ? Theme.inverted : option.hovered ? Theme.surfaceHigh : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }
                }
                contentItem: Column {
                    spacing: 2
                    opacity: option.enabled || ControlHub.busy ? 1 : 0.3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: option.modelData.icon
                        font.family: Theme.fontIcons
                        font.pixelSize: 18
                        color: option.checked ? Theme.invertedFg : Theme.fgDim
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Cfg.t(option.modelData.title)
                        font.family: Theme.font
                        font.pixelSize: 9
                        color: option.checked ? Theme.invertedFg : Theme.fgDim
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
    // Quick settings: Do Not Disturb, and the phone through KDE Connect when it
    // is installed. The camera switch lives with the island's action buttons.
    Row {
        x: 8; y: 59
        width: parent.width - 16
        spacing: 6
        readonly property real tileWidth: phone.status === Loader.Ready ? (width - spacing) / 2 : width
        // Do Not Disturb stays on until it is turned off again.
        QuickTile {
            width: parent.tileWidth
            enabled: !Backend.preview
            on: Notifs.muted
            glyph: Notifs.muted ? "do_not_disturb_on" : "do_not_disturb_off"
            label: Cfg.t("DND TILE")
            onClicked: Notifs.toggleMute()
        }
        Loader {
            id: phone
            width: parent.tileWidth
            height: 36
            active: !Backend.preview
            source: "PhoneTile.qml"
            visible: status === Loader.Ready
        }
    }
}
