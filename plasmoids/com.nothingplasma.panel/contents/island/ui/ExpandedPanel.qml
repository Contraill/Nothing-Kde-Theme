import QtQuick
import org.kde.kirigami as Kirigami
import "."
Item {
    id: root

    implicitWidth: Theme.expandedWidth
    implicitHeight: mainColumn.implicitHeight + 14 + 12 + (root.notifying ? Theme.notifStrip : 0)
    property string overlay: ""

    readonly property bool notifying: Notifs.current !== null

    function openOverlay(name) {
        if (name === "brightness" && !(Backend.controls?.brightnessDetailsAvailable ?? false)) return;
        overlay = name;
    }
    function closeOverlay() {
        overlay = "";
    }
    Connections {
        target: Backend.controls
        ignoreUnknownSignals: true
        function onBrightnessDetailsAvailableChanged() {
            if (root.overlay === "brightness" && !Backend.controls.brightnessDetailsAvailable) root.closeOverlay();
        }
    }

    Rectangle {
        id: island
        anchors.fill: parent
        radius: Theme.expandedRadius
        color: Theme.surface
        clip: true
        Item {
            id: notifView
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.notifStrip

            opacity: root.notifying ? 1 : 0
            visible: opacity > 0
            z: 3

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durShort
                }
            }

            transform: Translate {
                y: root.notifying ? 0 : 10
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasizedDecel
                    }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                height: 1
                color: Theme.outline
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                spacing: 12

                Kirigami.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    source: Notifs.current?.icon ?? ""
                    implicitWidth: 28
                    implicitHeight: 28
                    visible: (Notifs.current?.icon ?? "") !== ""
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    spacing: 1

                    Text {
                        width: parent.width
                        text: Notifs.current?.summary ?? ""
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.bodySmall
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: Notifs.current?.body ?? ""
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: Theme.labelSmall
                        elide: Text.ElideRight
                    }
                }
            }
        }
        Item {
            id: panel
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 12 + (root.notifying ? Theme.notifStrip : 0)

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: Theme.durMedium
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.emphasized
                }
            }
            Item {
                id: panelContent
                anchors.fill: parent

                opacity: root.overlay !== "" ? 0.45 : 1
                scale: root.overlay !== "" ? 0.97 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }

                Column {
                    id: mainColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 10
                    Item {
                        width: parent.width
                        height: 44

                        Timer {
                            id: panelClock
                            property date now: new Date()
                            interval: 1000
                            running: true
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: now = new Date()
                        }
                        Row {
                            id: bigClock
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            TextMetrics {
                                id: moldeHora
                                font: horaTxt.font
                                text: horaTxt.text.replace(/[0-9]/g, "0")
                            }

                            Text {
                                id: horaTxt
                                anchors.bottom: parent.bottom
                                width: moldeHora.width
                                // Keep the reserved clock width stable, but put
                                // narrow digits next to the seconds, not the left edge.
                                horizontalAlignment: Text.AlignRight
                                text: Qt.formatDateTime(panelClock.now, Cfg.fmtHora)
                                color: Theme.fg
                                font.family: Theme.fontDots
                                font.pixelSize: Theme.displayLarge
                                font.weight: Font.Bold
                            }

                            TextMetrics {
                                id: moldeSeg
                                font: segTxt.font
                                text: "00"
                            }

                            Text {
                                id: segTxt
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 4
                                width: moldeSeg.width
                                text: Qt.formatDateTime(panelClock.now, "ss")
                                color: Theme.fgDim
                                font.family: Theme.fontDots
                                font.pixelSize: Theme.displaySmall
                                font.weight: Font.Bold
                            }
                        }
                        Battery {
                            id: headerBattery
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            detailed: true
                            visible: Cfg.showBattery && present
                        }
                        Rectangle {
                            anchors.left: bigClock.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(0, Math.min(dateText.implicitWidth + 20,
                                (headerBattery.visible ? headerBattery.x - 8 : parent.width) - x))
                            height: 42
                            radius: Theme.shapeMd
                            color: fechaMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }

                            Column {
                                id: fechaCol
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    id: dateText
                                    width: Math.max(0, parent.parent.width - 20)
                                    elide: Text.ElideRight
                                    text: Cfg.locale.toString(panelClock.now, "dddd, d MMMM").toLocaleUpperCase(Cfg.locale.name)
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelMedium
                                    font.letterSpacing: Theme.labelSpacing
                                }

                                Text {
                                    text: Cfg.t("CALENDAR")
                                    color: fechaMa.containsMouse ? Theme.fgDim : Theme.fgFaint
                                    font.family: Theme.font
                                    font.pixelSize: Theme.labelSmall
                                    font.letterSpacing: Theme.labelSpacing
                                }
                            }

                            MouseArea {
                                id: fechaMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openOverlay("cal")
                            }
                        }
                    }
                    StatusPills {
                        width: parent.width
                        onRequestPanel: mode => root.openOverlay(mode)
                    }
                    MediaCard {
                        width: parent.width
                    }
                    Item {
                        width: parent.width
                        height: 106

                        PowerPrivacyCard {
                            id: recCard
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * 0.42
                        }
                        Rectangle {
                            anchors.left: recCard.right
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            radius: Theme.shapeLg
                            color: Theme.containerHigh

                            Meters {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        visible: ControlHub.error.length > 0
                        text: ControlHub.error
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        color: Theme.alert
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                    QuickActions {
                        width: parent.width
                        onRequestNotifs: root.openOverlay("notif")
                        onRequestPower: root.openOverlay("power")
                        onRequestSettings: root.openOverlay("settings")
                    }
                }
            }

        }
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.overlay !== "" ? 0.55 : 0
            visible: opacity > 0
            z: 4

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durMedium
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.emphasized
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeOverlay()
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 12 + (root.notifying ? Theme.notifStrip : 0)
            z: 5
            visible: overlayBox.opacity > 0

                Rectangle {
                    id: overlayBox
                    anchors.centerIn: parent
                    width: parent.width
                    height: Math.min(parent.height, overlayLoader.implicitHeight > 0 ? overlayLoader.implicitHeight + 28 : parent.height)
                    radius: Theme.shapeLg
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.outline
                    clip: true

                    opacity: root.overlay !== "" ? 1 : 0
                    scale: root.overlay !== "" ? 1 : 0.94

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durShort
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
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
                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.durMedium
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasized
                        }
                    }

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 14
                        contentHeight: overlayLoader.implicitHeight
                        // A color gesture belongs to the picker until release,
                        // even outside its bounds; normal scrolling stays available.
                        interactive: !((overlayLoader.item as AccentSettings)?.colorDragActive ?? false)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                    Loader {
                        id: overlayLoader
                        width: parent.width
                        active: root.overlay !== ""

                        sourceComponent: {
                            if (root.overlay === "weather") return weatherComp;
                            if (root.overlay === "wifi" || root.overlay === "bt")
                                return connComp;
                            if (root.overlay === "audio")
                                return audioComp;
                            if (root.overlay === "brightness" && (Backend.controls?.brightnessDetailsAvailable ?? false))
                                return brightnessComp;
                            if (root.overlay === "notif")
                                return notifComp;
                            if (root.overlay === "cal")
                                return calComp;
                            if (root.overlay === "power")
                                return powerComp;
                            if (root.overlay === "settings")
                                return settingsComp;
                            return null;
                        }
                    }
                    }

                    Component {
                        id: connComp
                        ConnPanel {
                            mode: root.overlay
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: audioComp
                        AudioPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: brightnessComp
                        BrightnessPanel { onClosed: root.closeOverlay() }
                    }

                    Component {
                        id: notifComp
                        NotifPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: calComp
                        CalendarPanel {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: powerComp
                        PowerView {
                            onClosed: root.closeOverlay()
                        }
                    }

                    Component {
                        id: weatherComp
                        WeatherSettings { onClosed: root.closeOverlay() }
                    }

                    Component {
                        id: settingsComp
                        AccentSettings {
                            onClosed: root.closeOverlay()
                        }
                    }
                }
        }
    }
}
