import QtQuick
import org.kde.plasma.core as PlasmaCore
import "."

// Live state that deserves a glance: running KDE jobs and a recording microphone.
Row {
    id: root
    spacing: 8

    Item {
        id: jobs
        readonly property var summary: Notifs.jobSummary
        visible: summary.count > 0
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: jobRow.implicitWidth
        implicitHeight: 24
        Row {
            id: jobRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "downloading"
                color: Theme.primary
                font.family: Theme.fontIcons
                font.pixelSize: 16
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: jobs.summary.percent + "%"
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.labelMedium
            }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            radius: 1
            color: Theme.surfaceHigh
            Rectangle {
                width: parent.width * jobs.summary.percent / 100
                height: parent.height
                radius: parent.radius
                color: Theme.primary
            }
        }
        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: Cfg.t("RUNNING JOBS") + " · " + jobs.summary.count
            subText: jobs.summary.percent + "%"
            location: PlasmaCore.Types.TopEdge
        }
    }

    // Privacy dot, like a phone's: something is recording from a microphone.
    Rectangle {
        visible: Audio.microphoneInUse
        anchors.verticalCenter: parent.verticalCenter
        width: micRow.implicitWidth + 12
        height: 22
        radius: height / 2
        color: Qt.alpha(Theme.alert, 0.18)
        Accessible.role: Accessible.StaticText
        Accessible.name: Cfg.t("MICROPHONE IN USE") + ": " + Audio.recordingApps.join(", ")
        Row {
            id: micRow
            anchors.centerIn: parent
            spacing: 3
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: Theme.alert
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.inputMuted ? "mic_off" : "mic"
                color: Theme.alert
                font.family: Theme.fontIcons
                font.pixelSize: 14
            }
        }
        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: Cfg.t("MICROPHONE IN USE")
            subText: Audio.recordingApps.join(", ") + (Audio.inputMuted ? " · " + Cfg.t("MICROPHONE MUTED") : "")
            location: PlasmaCore.Types.TopEdge
        }
    }
}
