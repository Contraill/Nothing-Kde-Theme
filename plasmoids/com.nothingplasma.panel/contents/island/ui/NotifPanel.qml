import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NM
import "."
Item {
    id: popup

    signal closed

    implicitHeight: col.implicitHeight + 44

    readonly property int count: Notifs.count

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10
        Item {
            width: parent.width
            height: 26

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Cfg.t("NOTIFICATIONS")
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                radius: height / 2
                color: closeMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: closeMa.containsMouse ? Theme.fg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 15
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.closed()
                }
            }
        }
        Row {
            width: parent.width
            spacing: 8
            Rectangle {
                width: (parent.width - 8) * 0.62
                height: 46
                radius: Theme.shapeLg
                color: Notifs.muted ? Theme.inverted : muteMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durMedium
                    }
                }

                Text {
                    id: muteIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.muted ? "notifications_off" : "notifications"
                    color: Notifs.muted ? Theme.invertedFg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 19
                }

                Text {
                    anchors.left: muteIcon.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifs.muted ? Cfg.t("MUTED") : Cfg.t("MUTE")
                    color: Notifs.muted ? Theme.invertedFg : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }

                MouseArea {
                    id: muteMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.toggleMute()
                }
            }

            Rectangle {
                width: (parent.width - 8) * 0.38
                height: 46
                radius: Theme.shapeLg
                color: clearMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                opacity: popup.count > 0 ? 1 : 0.4

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    id: clearIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "delete_sweep"
                    color: Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 19
                }

                Text {
                    anchors.left: clearIcon.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: Cfg.t("CLEAR")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: popup.count > 0
                    onClicked: Notifs.clearAll()
                }
            }
        }

        Text {
            text: popup.count + (Cfg.turkish ? " BİLDİRİM" : " NOTIFICATIONS")
            color: Theme.outline
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.weight: Font.Medium
            font.letterSpacing: 0.6
            visible: popup.count > 0
        }
        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: Notifs.model

                Rectangle {
                    id: nrow
                    required property int index
                    required property string summary
                    required property string body
                    required property string applicationIconName

                    width: col.width
                    height: 56
                    radius: Theme.shapeMd
                    color: nrowMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durShort
                        }
                    }

                    Kirigami.Icon {
                        id: nicon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 26
                        implicitHeight: 26
                        source: nrow.applicationIconName
                        visible: nrow.applicationIconName !== ""
                    }

                    Text {
                        anchors.centerIn: nicon
                        visible: !nicon.visible
                        text: "notifications"
                        color: Theme.fgFaint
                        font.family: Theme.fontIcons
                        font.pixelSize: 20
                    }

                    Column {
                        anchors.left: nicon.right
                        anchors.leftMargin: 10
                        anchors.right: ndismiss.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: nrow.summary
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.bodySmall
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: nrow.body
                            color: Theme.fgVariant
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }

                    Text {
                        id: ndismiss
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "close"
                        color: dismissMa.containsMouse ? Theme.fg : Theme.outline
                        font.family: Theme.fontIcons
                        font.pixelSize: 16

                        MouseArea {
                            id: dismissMa
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.dismissAt(nrow.index)
                        }
                    }

                    MouseArea {
                        id: nrowMa
                        anchors.fill: parent
                        anchors.rightMargin: 30
                        hoverEnabled: true
                    }
                }
            }
        }
        Column {
            width: parent.width
            spacing: 8
            visible: popup.count === 0
            topPadding: 16
            bottomPadding: 16

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "notifications_none"
                color: Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 34
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Cfg.t("NO NOTIFICATIONS")
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: Font.Medium
                font.letterSpacing: Theme.labelSpacing
            }
        }
    }
}
