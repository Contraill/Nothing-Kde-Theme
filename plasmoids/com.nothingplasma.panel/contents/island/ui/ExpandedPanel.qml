// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami
import "."

// The open island: clock, date and battery; connection and sound pills; the
// player; power profile and privacy beside the system meters; quick actions.
// Panels (calendar, Wi-Fi, sound, settings…) open over it by name, and the
// newest notification slides in along the bottom.
Item {
    id: root

    implicitWidth: Theme.expandedWidth
    implicitHeight: content.implicitHeight + 14 + 12 + (notifying ? Theme.notifStrip : 0)

    // The open panel's name, "" for none.
    property string overlay: ""
    readonly property bool notifying: Notifs.current !== null

    function openOverlay(name) {
        if (name === "brightness" && !(Backend.controls?.brightnessDetailsAvailable ?? false)) return;
        overlay = name;
    }
    function closeOverlay() {
        overlay = "";
    }
    // The brightness panel goes when its details do (a display unplugged).
    Connections {
        target: Backend.controls
        ignoreUnknownSignals: true
        function onBrightnessDetailsAvailableChanged() {
            if (root.overlay === "brightness" && !Backend.controls.brightnessDetailsAvailable) root.closeOverlay();
        }
    }

    readonly property var panels: ({
        weather: weatherPanel, wifi: connectionPanel, bt: connectionPanel, audio: soundPanel,
        brightness: brightnessPanel, notif: notificationPanel, cal: calendarPanel, power: powerPanel, settings: settingsPanel
    })
    Component { id: weatherPanel; WeatherSettings { onClosed: root.closeOverlay() } }
    // Wi-Fi and Bluetooth share one panel; the name picks the side.
    Component { id: connectionPanel; ConnPanel { mode: root.overlay; onClosed: root.closeOverlay() } }
    Component { id: soundPanel; AudioPanel { onClosed: root.closeOverlay() } }
    Component { id: brightnessPanel; BrightnessPanel { onClosed: root.closeOverlay() } }
    Component { id: notificationPanel; NotifPanel { onClosed: root.closeOverlay() } }
    Component { id: calendarPanel; CalendarPanel { onClosed: root.closeOverlay() } }
    Component { id: powerPanel; PowerView { onClosed: root.closeOverlay() } }
    Component { id: settingsPanel; AccentSettings { onClosed: root.closeOverlay() } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.expandedRadius
        color: Theme.surface
        clip: true

        // The newest notification, under a hairline.
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.notifStrip
            z: 3
            opacity: root.notifying ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
            transform: Translate {
                y: root.notifying ? 0 : 10
                Behavior on y { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasizedDecel } }
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
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
                    implicitWidth: 28
                    implicitHeight: 28
                    source: Notifs.current?.icon ?? ""
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

        // The island's own content, dimmed and pushed back while a panel is open.
        Item {
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 12 + (root.notifying ? Theme.notifStrip : 0)
            opacity: root.overlay !== "" ? 0.45 : 1
            scale: root.overlay !== "" ? 0.97 : 1
            Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }
            Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }
            Behavior on scale { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }

            Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 10

                Item {
                    width: parent.width
                    height: 44
                    Timer {
                        id: ticker
                        property date now: new Date()
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: now = new Date()
                    }
                    // Hours and minutes keep the width of their widest digits so
                    // the date beside them does not jitter; seconds sit smaller.
                    Row {
                        id: clock
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        TextMetrics {
                            id: timeWidth
                            font: time.font
                            text: time.text.replace(/[0-9]/g, "0")
                        }
                        Text {
                            id: time
                            anchors.bottom: parent.bottom
                            width: timeWidth.width
                            horizontalAlignment: Text.AlignRight
                            text: Qt.formatDateTime(ticker.now, Cfg.timeFormat)
                            color: Theme.fg
                            font.family: Theme.fontDots
                            font.pixelSize: Theme.displayLarge
                            font.weight: Font.Bold
                        }
                        TextMetrics {
                            id: secondsWidth
                            font: seconds.font
                            text: "00"
                        }
                        Text {
                            id: seconds
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            width: secondsWidth.width
                            text: Qt.formatDateTime(ticker.now, "ss")
                            color: Theme.fgDim
                            font.family: Theme.fontDots
                            font.pixelSize: Theme.displaySmall
                            font.weight: Font.Bold
                        }
                    }
                    Battery {
                        id: battery
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        detailed: true
                        visible: Cfg.showBattery && present
                    }
                    // The date, which opens the calendar; it gives way to the battery.
                    Rectangle {
                        id: dateButton
                        anchors.left: clock.right
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, Math.min(date.implicitWidth + 20, (battery.visible ? battery.x - 8 : parent.width) - x))
                        height: 42
                        radius: Theme.shapeMd
                        color: Qt.alpha(Theme.fg, dateArea.containsMouse ? Theme.stateHover : 0)
                        Behavior on color { ColorAnimation { duration: Theme.durShort } }
                        Column {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                id: date
                                width: Math.max(0, dateButton.width - 20)
                                elide: Text.ElideRight
                                text: Cfg.locale.toString(ticker.now, "dddd, d MMMM").toLocaleUpperCase(Cfg.locale.name)
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.labelMedium
                                font.letterSpacing: Theme.labelSpacing
                            }
                            Text {
                                text: Cfg.t("CALENDAR")
                                color: dateArea.containsMouse ? Theme.fgDim : Theme.fgFaint
                                font.family: Theme.font
                                font.pixelSize: Theme.labelSmall
                                font.letterSpacing: Theme.labelSpacing
                            }
                        }
                        MouseArea {
                            id: dateArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openOverlay("cal")
                        }
                    }
                }
                StatusPills {
                    width: parent.width
                    onRequestPanel: name => root.openOverlay(name)
                }
                MediaCard {
                    width: parent.width
                }
                Item {
                    width: parent.width
                    height: 106
                    PowerPrivacyCard {
                        id: powerPrivacy
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * 0.42
                    }
                    Rectangle {
                        anchors.left: powerPrivacy.right
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 8
                        radius: Theme.shapeLg
                        color: Theme.surfaceAlt
                        Meters {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                // Camera and microphone helper failures.
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

        // A scrim behind an open panel; clicking it closes the panel.
        Rectangle {
            anchors.fill: parent
            z: 4
            color: "#000000"
            opacity: root.overlay !== "" ? 0.55 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }
            MouseArea {
                anchors.fill: parent
                onClicked: root.closeOverlay()
            }
        }

        // The open panel: as tall as it needs, scrolling beyond the island.
        Item {
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: 12 + (root.notifying ? Theme.notifStrip : 0)
            z: 5
            visible: panelBox.opacity > 0
            Rectangle {
                id: panelBox
                anchors.centerIn: parent
                width: parent.width
                height: Math.min(parent.height, panelLoader.implicitHeight > 0 ? panelLoader.implicitHeight + 28 : parent.height)
                radius: Theme.shapeLg
                color: Theme.surface
                border.width: 1
                border.color: Theme.outline
                clip: true
                opacity: root.overlay !== "" ? 1 : 0
                scale: root.overlay !== "" ? 1 : 0.94
                Behavior on opacity { NumberAnimation { duration: Theme.durShort; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }
                // A small spring as the panel arrives.
                Behavior on scale { SpringAnimation { spring: 9.0; damping: 0.5; mass: 0.35; epsilon: 0.005 } }
                Behavior on height { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 14
                    contentHeight: panelLoader.implicitHeight
                    // A colour drag belongs to the picker until release, even
                    // outside its bounds; otherwise the panel scrolls.
                    interactive: !((panelLoader.item as AccentSettings)?.colorDragActive ?? false)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Loader {
                        id: panelLoader
                        width: parent.width
                        active: root.overlay !== ""
                        sourceComponent: root.panels[root.overlay] ?? null
                    }
                }
            }
        }
    }
}
