import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import "."
Item {
    id: popup

    signal closed
    property var panelConfig: Plasmoid.configuration
    readonly property bool confirmPowerActions: panelConfig?.confirmPowerActions ?? true
    signal actionRequested(string command)
    onActionRequested: command => correr(command)
    onConfirmPowerActionsChanged: confirmando = ""
    function requestAction(title, command, confirmable) {
        if (executing) return;
        if (!confirmable || !confirmPowerActions) {
            confirmando = "";
            actionRequested(command);
        } else confirmando = confirmando === title ? "" : title;
    }
    readonly property int listaMax: 344

    implicitHeight: col.implicitHeight + 30
    property string confirmando: ""
    property bool puedeSuspender: false
    property bool puedeHibernar: false
    readonly property bool executing: ControlHub.busy

    readonly property string cmdPuede: 'busctl --user --json=short call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement CanSuspend; echo ---; busctl --user --json=short call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement CanHibernate'

    Component.onCompleted: if (!Backend.preview) popup.consulta.connectSource(Exec.command(popup.cmdPuede))
    readonly property P5Support.DataSource consulta: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const partes = String(data["stdout"] ?? "").split("---");
            popup.puedeSuspender = partes.length > 0 && partes[0].indexOf("true") >= 0;
            popup.puedeHibernar = partes.length > 1 && partes[1].indexOf("true") >= 0;
        }
    }

    function correr(cmd) {
        if (Backend.preview || executing) return;
        Exec.run(cmd);
        popup.closed();
    }

    Item {
        id: card
        anchors.fill: parent

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
                    text: Cfg.t("POWER")
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
            component Opcion: Rectangle {
                id: op
                property string icono: ""
                property string titulo: ""
                property string detalle: ""
                property string comando: ""
                property bool pesada: false
                enabled: !popup.executing

                readonly property bool preguntando: popup.confirmando === op.titulo

                width: lista.width
                height: preguntando ? 78 : 44
                radius: Theme.shapeMd
                color: opMa.containsMouse || op.preguntando ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }

                Item {
                    id: fila
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 44

                    Text {
                        id: opIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: op.icono
                        color: op.pesada ? Theme.alert : Theme.fg
                        font.family: Theme.fontIcons
                        font.pixelSize: 20
                    }

                    Column {
                        anchors.left: opIcon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            width: parent.width
                            text: op.titulo
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.bodySmall
                            font.weight: Font.Medium
                            font.letterSpacing: Theme.labelSpacing
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: op.detalle !== ""
                            text: op.detalle
                            color: Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: opMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.requestAction(op.titulo, op.comando, op.pesada);
                        }
                    }
                }
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 46
                    anchors.top: fila.bottom
                    anchors.topMargin: 2
                    spacing: 6
                    visible: op.preguntando

                    Rectangle {
                        width: siTxt.implicitWidth + 24
                        height: 28
                        radius: height / 2
                        color: siMa.containsMouse ? Qt.lighter(Theme.alert, 1.15) : Theme.alert

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durShort
                            }
                        }

                        Text {
                            id: siTxt
                            anchors.centerIn: parent
                            text: Cfg.t("YES")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            font.weight: Font.Medium
                            font.letterSpacing: Theme.labelSpacing
                        }

                        MouseArea {
                            id: siMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.actionRequested(op.comando)
                        }
                    }

                    Rectangle {
                        width: noTxt.implicitWidth + 24
                        height: 28
                        radius: height / 2
                        color: noMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)
                        border.width: 1
                        border.color: Theme.outline

                        Text {
                            id: noTxt
                            anchors.centerIn: parent
                            text: Cfg.t("CANCEL")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            font.weight: Font.Medium
                            font.letterSpacing: Theme.labelSpacing
                        }

                        MouseArea {
                            id: noMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.confirmando = ""
                        }
                    }
                }
            }
            Item {
                width: parent.width
                height: Math.min(popup.listaMax, lista.contentHeight)

                Flickable {
                    id: lista
                    anchors.fill: parent
                    contentHeight: dentro.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 3500

                    Column {
                        id: dentro
                        width: lista.width
                        spacing: 6

            Opcion {
                icono: "lock"
                titulo: Cfg.t("LOCK")
                detalle: Cfg.t("Asks for the password on return")
                comando: "busctl --user call org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver Lock"
            }

            Opcion {
                icono: "logout"
                titulo: Cfg.t("LOG OUT")
                detalle: Cfg.t("Closes the open programs")
                comando: "busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown logout"
                pesada: true
            }

            Opcion {
                icono: "bedtime"
                titulo: Cfg.t("SLEEP")
                detalle: Cfg.t("Screen off, everything stays as it is")
                comando: "busctl --user call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement Suspend"
                visible: popup.puedeSuspender
                pesada: true
            }

            Opcion {
                icono: "downloading"
                titulo: Cfg.t("HIBERNATE")
                detalle: Cfg.t("Saves everything to disk and powers off")
                comando: "busctl --user call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement Hibernate"
                visible: popup.puedeHibernar
                pesada: true
            }

            Opcion {
                icono: "restart_alt"
                titulo: Cfg.t("RESTART")
                detalle: Cfg.t("Powers off and starts again")
                comando: "busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown logoutAndReboot"
                pesada: true
            }

            Opcion {
                icono: "power_settings_new"
                titulo: Cfg.t("SHUT DOWN")
                detalle: Cfg.t("Powers off the computer")
                comando: "busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown logoutAndShutdown"
                pesada: true
            }
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    width: 3
                    radius: 1.5
                    color: Theme.fgFaint

                    visible: lista.contentHeight > lista.height
                    height: Math.max(24, lista.height * (lista.height / lista.contentHeight))
                    y: (lista.contentHeight <= lista.height) ? 0 : (lista.contentY / (lista.contentHeight - lista.height)) * (lista.height - height)

                    opacity: lista.moving ? 0.9 : 0.25

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durMedium
                        }
                    }
                }
            }
            Text {
                width: parent.width
                text: popup.executing ? Cfg.t("WORKING") : ""
                visible: text.length > 0
                color: Theme.alert
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                wrapMode: Text.WordWrap
            }
        }
    }
}
