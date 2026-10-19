// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's uptime (Prince-1652, MIT): today's time on and a bar for
// each day of the week on a baseline, today in the accent. Click a bar for
// its hours.
Glassy.EveryFrame {
    id: f
    property string family
    // Seven {label, seconds, today, future}.
    property var days: []
    property string todayText: "0h 0m"
    property int picked: -1
    designWidth: 390
    designHeight: 190
    card: "block"

    function hours(seconds) {
        return Math.floor(seconds / 3600) + "h " + Math.floor(seconds % 3600 / 60) + "m";
    }
    component Label: Glassy.EveryText {
        s: f.s
        color: f.colors.textPrimary
        font.family: f.family
    }
    MouseArea {
        anchors.fill: parent
        onClicked: f.picked = -1
    }
    Label { px: 30; py: 20; pt: 16; upper: true; value: i18n("Uptime") }
    Label { px: 360; py: 20; pt: 16; align: "Right"; value: f.todayText }
    Rectangle {
        x: 30 * f.s; y: 139 * f.s; width: 330 * f.s; height: 2 * f.s
        color: f.track
    }
    Repeater {
        model: f.days
        Item {
            id: column
            required property var modelData
            required property int index
            readonly property real centre: 45 + index * 50
            readonly property real tall: modelData.future || modelData.seconds <= 0 ? 0 : Math.max(4, 75 * Math.min(1, modelData.seconds / 86400))
            // Rounded at the top, square on the baseline.
            Item {
                x: (column.centre - 8) * f.s
                y: (140 - column.tall) * f.s
                width: 16 * f.s
                height: column.tall * f.s
                clip: true
                Rectangle {
                    width: parent.width
                    height: parent.height + 4 * f.s
                    radius: 4 * f.s
                    color: column.modelData.today ? f.colors.accent : f.colors.textPrimary
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: f.picked = f.picked === column.index ? -1 : column.index
                }
            }
            Label {
                px: column.centre; py: 155; pt: 11; align: "Center"; upper: true
                value: column.modelData.label
                color: column.modelData.today ? f.colors.accent : f.colors.textPrimary
            }
            Label {
                visible: f.picked === column.index
                px: column.centre; py: 140 - column.tall - 5; pt: 10; align: "CenterBottom"
                value: f.hours(column.modelData.seconds)
            }
        }
    }
}
