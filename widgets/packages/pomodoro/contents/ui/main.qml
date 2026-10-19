// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notification
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"

// Pomodoro timer. Its state lives in the configuration (an end time while
// running, the remaining seconds while paused), so it survives restarts.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
        monochrome: Plasmoid.configuration.monochrome
    }
    Glassy.DotFont { id: dotFont }

    readonly property var config: Plasmoid.configuration
    // 0 focus, 1 short break, 2 long break.
    readonly property int phase: config.phase
    readonly property int rounds: Math.max(1, config.roundsBeforeLongBreak)
    readonly property int total: 60 * Math.max(1, [config.focusMinutes, config.breakMinutes, config.longBreakMinutes][phase] ?? config.focusMinutes)
    readonly property bool running: config.endsAt > 0
    property double now: Date.now()
    readonly property int remaining: running ? Math.max(0, Math.ceil((config.endsAt - now) / 1000))
        : config.remainingSeconds >= 0 ? Math.min(config.remainingSeconds, total) : total

    function start() {
        config.endsAt = Date.now() + remaining * 1000;
        config.remainingSeconds = -1;
        now = Date.now();
    }
    function pause() {
        config.remainingSeconds = remaining;
        config.endsAt = 0;
    }
    function reset() {
        config.endsAt = 0;
        config.remainingSeconds = -1;
    }
    // A finished focus period counts as a round; every few rounds the break is long.
    function advance() {
        if (phase === 0) {
            config.round = config.round + 1;
            config.phase = config.round % rounds === 0 ? 2 : 1;
        } else {
            config.phase = 0;
        }
        reset();
    }
    function finish() {
        finished.title = phase === 0 ? i18n("Focus finished") : i18n("Break is over");
        finished.text = phase === 0 ? i18n("Time for a break.") : i18n("Back to focus.");
        finished.sendEvent();
        advance();
    }
    function clock(seconds) {
        const m = Math.floor(seconds / 60), s = seconds % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    Notification {
        id: finished
        componentName: "plasma_applet_timer"
        eventId: "timerFinished"
        iconName: "chronometer"
    }
    Timer {
        interval: 250
        repeat: true
        running: root.running
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now();
            if (root.remaining <= 0) root.finish();
        }
    }

    component RoundButton: QQC2.AbstractButton {
        id: button
        property string iconName: ""
        property bool primary: false
        implicitWidth: primary ? 40 : 32
        implicitHeight: implicitWidth
        background: Rectangle {
            radius: width / 2
            color: button.primary ? nColors.textPrimary
                : button.hovered ? nColors.alpha(nColors.textPrimary, 0.12) : "transparent"
        }
        contentItem: Kirigami.Icon {
            source: button.iconName
            isMask: true
            color: button.primary ? nColors.background : nColors.textPrimary
            implicitWidth: button.primary ? 20 : 16
            implicitHeight: implicitWidth
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 240
        Layout.minimumWidth: 180
        Layout.minimumHeight: 200

        Glassy.GlassySurface {
            bare: Plasmoid.configuration.transparent
            id: card
            anchors.fill: parent
            anchors.margins: 10
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 14
            spacing: 8
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Glassy.DotRing {
                    id: ring
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    count: 60
                    value: 1 - root.remaining / root.total
                    litColor: nColors.accent
                    dimColor: nColors.divider
                }
                Column {
                    anchors.centerIn: ring
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.clock(root.remaining)
                        font.family: dotFont.name
                        font.pixelSize: ring.width * 0.22
                        color: nColors.textPrimary
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: [i18n("FOCUS"), i18n("BREAK"), i18n("LONG BREAK")][root.phase] ?? ""
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                        color: nColors.textSecondary
                    }
                    // Rounds done before the next long break.
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4
                        Repeater {
                            model: root.rounds
                            Rectangle {
                                required property int index
                                width: 5
                                height: 5
                                radius: 2.5
                                color: index < Plasmoid.configuration.round % root.rounds ? nColors.accent : nColors.divider
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14
                RoundButton {
                    iconName: "view-refresh-symbolic"
                    Accessible.name: i18n("Reset")
                    onClicked: root.reset()
                }
                RoundButton {
                    primary: true
                    iconName: root.running ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                    Accessible.name: root.running ? i18n("Pause") : i18n("Start")
                    onClicked: root.running ? root.pause() : root.start()
                }
                RoundButton {
                    iconName: "media-skip-forward-symbolic"
                    Accessible.name: i18n("Skip")
                    onClicked: root.advance()
                }
            }
        }
    }
}
