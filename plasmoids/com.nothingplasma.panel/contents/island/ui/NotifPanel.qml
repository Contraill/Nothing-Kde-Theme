// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami
import "."

// Notification history: do not disturb and clear, then every notification
// (grouped by application when Plasma groups them) with its actions and an
// inline reply.
Item {
    id: root

    signal closed
    implicitHeight: content.implicitHeight + 44

    readonly property int count: Notifs.count
    // Opening the panel counts as seeing everything.
    Component.onCompleted: Notifs.markSeen("")
    // Keeps "5 min ago" current.
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: Notifs.clock++
    }

    // Do not disturb and clear: an icon and a label on a wide card.
    component WideButton: Rectangle {
        id: wide
        property string icon
        property string label
        property bool on: false
        property int gap: 10
        signal clicked
        height: 46
        radius: Theme.shapeLg
        color: on ? Theme.inverted : area.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
        Text {
            id: glyph
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: wide.icon
            color: wide.on ? Theme.invertedFg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 19
        }
        Text {
            anchors.left: glyph.right
            anchors.leftMargin: wide.gap
            anchors.verticalCenter: parent.verticalCenter
            text: wide.label
            color: wide.on ? Theme.invertedFg : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.bodySmall
            font.weight: Font.Medium
            font.letterSpacing: Theme.labelSpacing
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: wide.clicked()
        }
    }

    // An action or the reply button under a notification.
    component Chip: Rectangle {
        id: chip
        property string label
        property bool active: false
        signal triggered
        width: caption.implicitWidth + 20
        height: 26
        radius: 13
        color: active ? Theme.inverted : area.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
        Accessible.role: Accessible.Button
        Accessible.name: label
        Accessible.onPressAction: chip.triggered()
        Text {
            id: caption
            anchors.centerIn: parent
            text: chip.label
            textFormat: Text.PlainText
            color: chip.active ? Theme.invertedFg : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.weight: Font.Medium
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.triggered()
        }
    }

    // A small icon button: dismiss one, or clear a group.
    component IconAction: Text {
        id: action
        property string label
        signal clicked
        color: area.containsMouse ? Theme.fg : Theme.fgFaint
        font.family: Theme.fontIcons
        font.pixelSize: 16
        Accessible.role: Accessible.Button
        Accessible.name: label
        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    component NotificationRow: Rectangle {
        id: row
        required property int index
        required property var model
        readonly property bool isGroup: model.isGroup === true
        readonly property bool inGroup: model.isInGroup === true
        readonly property var actionNames: model.actionNames ?? []
        readonly property var actionLabels: model.actionLabels ?? []
        readonly property bool canOpen: model.hasDefaultAction === true
        readonly property bool canReply: model.hasReplyAction === true
        // The application's icon, else the one the notification sent.
        readonly property string iconSource: model.applicationIconName || model.iconName || ""
        property bool replying: false

        width: content.width
        height: isGroup ? 30 : details.implicitHeight + 16
        radius: Theme.shapeMd
        color: Qt.alpha(Theme.fg, !isGroup && area.containsMouse ? Theme.stateHover : 0)
        Behavior on color { ColorAnimation { duration: Theme.durShort } }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            enabled: !row.isGroup
            cursorShape: row.canOpen ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: Notifs.activate(row.index)
        }

        // A group's header: the application, how many, and clear.
        Text {
            visible: row.isGroup
            anchors.left: parent.left
            anchors.right: clearGroup.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: (row.model.applicationName || "") + " · " + (row.model.groupChildrenCount ?? 0)
            textFormat: Text.PlainText
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.weight: Font.Medium
            font.letterSpacing: 0.6
            elide: Text.ElideRight
        }
        IconAction {
            id: clearGroup
            visible: row.isGroup
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "clear_all"
            label: Cfg.t("CLEAR")
            onClicked: Notifs.dismissAt(row.index)
        }

        // Members of a group sit a little further in.
        Kirigami.Icon {
            id: icon
            visible: !row.isGroup && row.iconSource !== ""
            x: row.inGroup ? 18 : 10
            y: 10
            implicitWidth: 26
            implicitHeight: 26
            source: row.iconSource
        }
        Text {
            anchors.centerIn: icon
            visible: !row.isGroup && !icon.visible
            text: "notifications"
            color: Theme.fgFaint
            font.family: Theme.fontIcons
            font.pixelSize: 20
        }
        Column {
            id: details
            visible: !row.isGroup
            anchors.left: icon.right
            anchors.right: dismiss.left
            anchors.leftMargin: 10
            anchors.rightMargin: 6
            y: 8
            spacing: 2
            Item {
                width: parent.width
                height: summary.implicitHeight
                Text {
                    id: summary
                    anchors.left: parent.left
                    anchors.right: time.left
                    anchors.rightMargin: 6
                    text: row.model.summary ?? ""
                    textFormat: Text.PlainText
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodySmall
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    id: time
                    anchors.right: parent.right
                    anchors.verticalCenter: summary.verticalCenter
                    text: Notifs.timeText(row.model.updated ?? row.model.created)
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                }
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: row.model.body ?? ""
                // The notification spec allows basic markup in bodies.
                textFormat: Text.StyledText
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            // Up to three actions, and reply when the sender offers it.
            Flow {
                width: parent.width
                spacing: 6
                topPadding: 4
                visible: actions.count > 0 || row.canReply
                Repeater {
                    id: actions
                    model: Math.min(3, row.actionNames.length)
                    Chip {
                        required property int index
                        label: row.actionLabels[index] ?? ""
                        onTriggered: Notifs.invokeAction(row.index, row.actionNames[index])
                    }
                }
                Chip {
                    visible: row.canReply
                    label: row.model.replyActionLabel || Cfg.t("REPLY")
                    active: row.replying
                    onTriggered: row.replying = !row.replying
                }
            }
            Rectangle {
                width: parent.width
                height: 32
                radius: Theme.shapeSm
                color: Theme.surfaceAlt
                visible: row.replying
                onVisibleChanged: if (visible) reply.forceActiveFocus()
                TextInput {
                    id: reply
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
                        Notifs.reply(row.index, text);
                        text = "";
                        row.replying = false;
                    }
                    Keys.onEscapePressed: row.replying = false
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: reply.text === ""
                        text: row.model.replyPlaceholderText || Cfg.t("REPLY")
                        color: Theme.fgFaint
                        font: reply.font
                    }
                }
            }
        }
        IconAction {
            id: dismiss
            visible: !row.isGroup
            anchors.right: parent.right
            anchors.rightMargin: 10
            y: 12
            text: "close"
            label: Cfg.t("CLOSE")
            onClicked: Notifs.dismissAt(row.index)
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        PanelHeader {
            title: Cfg.t("NOTIFICATIONS")
            onClosed: root.closed()
        }
        Row {
            width: parent.width
            spacing: 8
            WideButton {
                width: (parent.width - 8) * 0.62
                icon: Notifs.muted ? "notifications_off" : "notifications"
                label: Cfg.t("DO NOT DISTURB")
                on: Notifs.muted
                Accessible.role: Accessible.CheckBox
                Accessible.name: label
                Accessible.checked: on
                onClicked: Notifs.toggleMute()
            }
            WideButton {
                width: (parent.width - 8) * 0.38
                icon: "delete_sweep"
                label: Cfg.t("CLEAR")
                gap: 8
                enabled: root.count > 0
                opacity: enabled ? 1 : 0.4
                onClicked: Notifs.clearAll()
            }
        }
        Text {
            visible: root.count > 0
            text: Cfg.t("N NOTIFICATIONS").replace("%1", Notifs.notificationCount)
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.weight: Font.Medium
            font.letterSpacing: 0.6
        }
        Column {
            width: parent.width
            spacing: 2
            Repeater {
                model: Notifs.model
                NotificationRow {}
            }
        }
        // Nothing to show.
        Column {
            width: parent.width
            visible: root.count === 0
            spacing: 8
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
