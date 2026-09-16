import QtQuick
import QtQuick.Controls as QQC2

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
    Row {
        x: 8; y: 59
        width: parent.width - 16
        spacing: 6
        component PrivacyButton: QQC2.AbstractButton {
            id: button
            property bool blocked: false
            property bool mixed: false
            property string glyph: ""
            property string label: ""
            property string explanation: ""
            width: (parent.width - 6) / 2
            height: 36
            Accessible.name: label + " · " + (mixed ? Cfg.t("PARTIAL") : (!enabled && !ControlHub.busy) ? Cfg.t("UNAVAILABLE") : blocked ? Cfg.t("PRIVACY OFF") : Cfg.t("PRIVACY ON"))
            Accessible.description: explanation
            background: Rectangle {
                radius: 11
                color: button.blocked ? Theme.inverted : button.hovered ? Theme.surfaceTop : Theme.surfaceHigh
                border.width: button.mixed ? 1 : 0
                border.color: Theme.alert
                Behavior on color { ColorAnimation { duration: Theme.durShort } }
            }
            contentItem: Row {
                spacing: 5
                opacity: button.enabled || ControlHub.busy ? 1 : 0.3
                leftPadding: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: button.glyph
                    font.family: Theme.fontIcons
                    font.pixelSize: 17
                    color: button.blocked ? Theme.invertedFg : Theme.fgDim
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ControlHub.busy ? "…" : button.label
                    font.family: Theme.font
                    font.pixelSize: 10
                    color: button.blocked ? Theme.invertedFg : Theme.fgDim
                }
            }
        }
        PrivacyButton {
            blocked: ControlHub.cameraBlocked
            mixed: ControlHub.cameraMixed
            enabled: !ControlHub.busy && ControlHub.cameraAvailable
            glyph: blocked ? "videocam_off" : "videocam"
            label: Cfg.t("CAMERA")
            explanation: Cfg.t("CAMERA HELP")
            onClicked: ControlHub.toggleCamera()
        }
        PrivacyButton {
            blocked: ControlHub.microphoneBlocked
            mixed: ControlHub.microphonePartial
            enabled: !ControlHub.busy && (ControlHub.microphoneAvailable || ControlHub.microphonePartial)
            glyph: blocked ? "mic_off" : "mic"
            label: Cfg.t("MICROPHONE")
            explanation: Cfg.t("MIC HELP")
            onClicked: ControlHub.toggleMicrophone()
        }
    }
}
