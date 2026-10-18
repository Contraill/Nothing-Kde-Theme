import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NM
import "."
Item {
    id: popup

    signal closed

    component NotifChip: Rectangle {
        id: chip
        property string label: ""
        property bool active: false
        signal triggered
        width: chipText.implicitWidth + 20
        height: 26
        radius: height / 2
        color: chip.active ? Theme.inverted : chipMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
        Accessible.role: Accessible.Button
        Accessible.name: chip.label
        Accessible.onPressAction: chip.triggered()
        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            textFormat: Text.PlainText
            color: chip.active ? Theme.invertedFg : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.weight: Font.Medium
        }
        MouseArea {
            id: chipMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.triggered()
        }
    }

    implicitHeight: col.implicitHeight + 44

    readonly property int count: Notifs.count
    Component.onCompleted: Notifs.markSeen("")
    readonly property int notificationCount: Notifs.notificationCount

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: Notifs.clock++
    }

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
                    text: Cfg.t("DO NOT DISTURB")
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
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: Cfg.t("DO NOT DISTURB")
                    Accessible.checked: Notifs.muted
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
            text: Cfg.t("N NOTIFICATIONS").replace("%1", popup.notificationCount)
            color: Theme.fgDim
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
                    required property var model
                    readonly property bool isGroup: model.isGroup === true
                    readonly property bool inGroup: model.isInGroup === true
                    readonly property var actionNames: model.actionNames ?? []
                    readonly property var actionLabels: model.actionLabels ?? []
                    readonly property bool canOpen: model.hasDefaultAction === true
                    readonly property bool canReply: model.hasReplyAction === true
                    property bool replying: false
                    // The application's icon, else the icon the notification itself sent.
                    readonly property string iconSource: model.applicationIconName || model.iconName || ""

                    width: col.width
                    height: isGroup ? 30 : body.implicitHeight + 16
                    radius: Theme.shapeMd
                    color: !isGroup && nrowMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durShort
                        }
                    }

                    MouseArea {
                        id: nrowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !nrow.isGroup
                        cursorShape: nrow.canOpen ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: Notifs.activate(nrow.index)
                    }

                    // Group header: application name, count and "clear group".
                    Text {
                        visible: nrow.isGroup
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: groupClear.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: (nrow.model.applicationName || "") + " · " + (nrow.model.groupChildrenCount ?? 0)
                        textFormat: Text.PlainText
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.labelSmall
                        font.weight: Font.Medium
                        font.letterSpacing: 0.6
                        elide: Text.ElideRight
                    }
                    Text {
                        id: groupClear
                        visible: nrow.isGroup
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "clear_all"
                        color: groupClearMa.containsMouse ? Theme.fg : Theme.fgFaint
                        font.family: Theme.fontIcons
                        font.pixelSize: 16
                        Accessible.role: Accessible.Button
                        Accessible.name: Cfg.t("CLEAR")
                        MouseArea {
                            id: groupClearMa
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.dismissAt(nrow.index)
                        }
                    }

                    Kirigami.Icon {
                        id: nicon
                        visible: !nrow.isGroup && nrow.iconSource !== ""
                        anchors.left: parent.left
                        anchors.leftMargin: nrow.inGroup ? 18 : 10
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        implicitWidth: 26
                        implicitHeight: 26
                        source: nrow.iconSource
                    }

                    Text {
                        anchors.centerIn: nicon
                        visible: !nrow.isGroup && !nicon.visible
                        text: "notifications"
                        color: Theme.fgFaint
                        font.family: Theme.fontIcons
                        font.pixelSize: 20
                    }

                    Column {
                        id: body
                        visible: !nrow.isGroup
                        anchors.left: nicon.right
                        anchors.leftMargin: 10
                        anchors.right: ndismiss.left
                        anchors.rightMargin: 6
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        spacing: 2

                        Item {
                            width: parent.width
                            height: summaryText.implicitHeight
                            Text {
                                id: summaryText
                                anchors.left: parent.left
                                anchors.right: timeText.left
                                anchors.rightMargin: 6
                                text: nrow.model.summary ?? ""
                                textFormat: Text.PlainText
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.bodySmall
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            Text {
                                id: timeText
                                anchors.right: parent.right
                                anchors.verticalCenter: summaryText.verticalCenter
                                text: Notifs.timeText(nrow.model.updated ?? nrow.model.created)
                                color: Theme.fgDim
                                font.family: Theme.font
                                font.pixelSize: Theme.labelSmall
                            }
                        }

                        Text {
                            width: parent.width
                            text: nrow.model.body ?? ""
                            // Notification bodies may carry the basic markup of the spec.
                            textFormat: Text.StyledText
                            color: Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            visible: text !== ""
                        }

                        Flow {
                            width: parent.width
                            spacing: 6
                            topPadding: 4
                            visible: actionRepeater.count > 0 || nrow.canReply

                            Repeater {
                                id: actionRepeater
                                model: Math.min(3, nrow.actionNames.length)
                                NotifChip {
                                    required property int index
                                    label: nrow.actionLabels[index] ?? ""
                                    onTriggered: Notifs.invokeAction(nrow.index, nrow.actionNames[index])
                                }
                            }
                            NotifChip {
                                visible: nrow.canReply
                                label: nrow.model.replyActionLabel || Cfg.t("REPLY")
                                active: nrow.replying
                                onTriggered: nrow.replying = !nrow.replying
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: Theme.shapeSm
                            color: Theme.surfaceAlt
                            visible: nrow.replying
                            onVisibleChanged: if (visible) replyInput.forceActiveFocus()

                            TextInput {
                                id: replyInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.bodySmall
                                selectByMouse: true
                                clip: true
                                onAccepted: {
                                    Notifs.reply(nrow.index, text);
                                    text = "";
                                    nrow.replying = false;
                                }
                                Keys.onEscapePressed: nrow.replying = false

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: replyInput.text === ""
                                    text: nrow.model.replyPlaceholderText || Cfg.t("REPLY")
                                    color: Theme.fgFaint
                                    font: replyInput.font
                                }
                            }
                        }
                    }

                    Text {
                        id: ndismiss
                        visible: !nrow.isGroup
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        text: "close"
                        color: dismissMa.containsMouse ? Theme.fg : Theme.fgFaint
                        font.family: Theme.fontIcons
                        font.pixelSize: 16
                        Accessible.role: Accessible.Button
                        Accessible.name: Cfg.t("CLOSE")

                        MouseArea {
                            id: dismissMa
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.dismissAt(nrow.index)
                        }
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
