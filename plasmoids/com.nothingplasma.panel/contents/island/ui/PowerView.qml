// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import "."

// Lock, log out, sleep, hibernate, restart and shut down through the
// session's own D-Bus services. Whatever ends the session asks once more,
// unless the island settings turn that off.
Item {
    id: root

    signal closed
    signal actionRequested(string command)
    property var panelConfig: Plasmoid.configuration
    readonly property bool confirmPowerActions: panelConfig?.confirmPowerActions ?? true
    readonly property bool executing: ControlHub.busy
    // The title of the action waiting for a yes.
    property string pending: ""
    property bool canSuspend: false
    property bool canHibernate: false

    onConfirmPowerActionsChanged: pending = ""
    onActionRequested: command => run(command)

    // A second click on the same action takes the question back.
    function requestAction(title, command, confirmable) {
        if (executing) return;
        if (confirmable && confirmPowerActions) {
            pending = pending === title ? "" : title;
        } else {
            pending = "";
            actionRequested(command);
        }
    }
    function run(command) {
        if (Backend.preview || executing) return;
        Exec.run(command);
        closed();
    }

    readonly property string session: "busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown "
    readonly property string power: "busctl --user call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement "
    readonly property var actions: [
        {icon: "lock", title: "LOCK", detail: "Asks for the password on return", confirm: false, shown: true,
            command: "busctl --user call org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver Lock"},
        {icon: "logout", title: "LOG OUT", detail: "Closes the open programs", confirm: true, shown: true, command: session + "logout"},
        {icon: "bedtime", title: "SLEEP", detail: "Screen off, everything stays as it is", confirm: true, shown: canSuspend, command: power + "Suspend"},
        {icon: "downloading", title: "HIBERNATE", detail: "Saves everything to disk and powers off", confirm: true, shown: canHibernate, command: power + "Hibernate"},
        {icon: "restart_alt", title: "RESTART", detail: "Powers off and starts again", confirm: true, shown: true, command: session + "logoutAndReboot"},
        {icon: "power_settings_new", title: "SHUT DOWN", detail: "Powers off the computer", confirm: true, shown: true, command: session + "logoutAndShutdown"}
    ]

    // PowerDevil knows whether this machine can sleep or hibernate.
    readonly property string capabilityQuery: 'busctl --user --json=short call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement CanSuspend; echo ---; busctl --user --json=short call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement CanHibernate'
    readonly property P5Support.DataSource capabilities: P5Support.DataSource {
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            const answers = String(data.stdout ?? "").split("---");
            root.canSuspend = answers[0].includes("true");
            root.canHibernate = (answers[1] ?? "").includes("true");
        }
    }
    Component.onCompleted: if (!Backend.preview) capabilities.connectSource(Exec.command(capabilityQuery))

    implicitHeight: content.implicitHeight + 30

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        PanelHeader {
            title: Cfg.t("POWER")
            onClosed: root.closed()
        }

        // Scrolls once the list outgrows the island.
        Item {
            width: parent.width
            height: Math.min(344, list.contentHeight)
            Flickable {
                id: list
                anchors.fill: parent
                contentHeight: options.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 3500
                Column {
                    id: options
                    width: list.width
                    spacing: 6
                    Repeater {
                        model: root.actions
                        Rectangle {
                            id: option
                            required property var modelData
                            readonly property string title: Cfg.t(modelData.title)
                            readonly property string command: modelData.command
                            readonly property bool asking: root.pending === title
                            visible: modelData.shown
                            enabled: !root.executing
                            width: options.width
                            height: asking ? 78 : 44
                            radius: Theme.shapeMd
                            color: area.containsMouse || asking ? Theme.surfaceHigh : Theme.surfaceAlt
                            Behavior on color { ColorAnimation { duration: Theme.durShort } }
                            Behavior on height { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }

                            Item {
                                id: row
                                width: parent.width
                                height: 44
                                Text {
                                    id: icon
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: option.modelData.icon
                                    // Red for whatever ends the session.
                                    color: option.modelData.confirm ? Theme.alert : Theme.fg
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 20
                                }
                                Column {
                                    anchors.left: icon.right
                                    anchors.right: parent.right
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        width: parent.width
                                        text: option.title
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.bodySmall
                                        font.weight: Font.Medium
                                        font.letterSpacing: Theme.labelSpacing
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: Cfg.t(option.modelData.detail)
                                        color: Theme.fgDim
                                        font.family: Theme.font
                                        font.pixelSize: Theme.labelSmall
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: area
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.requestAction(option.title, option.command, option.modelData.confirm)
                                }
                            }
                            // The question: yes in red, or cancel.
                            Row {
                                x: 46
                                anchors.top: row.bottom
                                anchors.topMargin: 2
                                spacing: 6
                                visible: option.asking
                                TextButton { label: Cfg.t("YES"); tone: "alert"; padding: 24; onClicked: root.actionRequested(option.command) }
                                TextButton { label: Cfg.t("CANCEL"); padding: 24; onClicked: root.pending = "" }
                            }
                        }
                    }
                }
            }
            ScrollHint { flickable: list }
        }
        Text {
            width: parent.width
            visible: root.executing
            text: Cfg.t("WORKING")
            color: Theme.alert
            font.family: Theme.font
            font.pixelSize: Theme.bodySmall
            wrapMode: Text.WordWrap
        }
    }
}
