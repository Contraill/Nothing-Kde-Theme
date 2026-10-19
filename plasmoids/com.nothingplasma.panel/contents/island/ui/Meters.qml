// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// CPU, memory and, when there is one, GPU load as bars with temperatures.
// Over 85 % a bar turns to the alert colour; temperatures stay in the accent.
Column {
    id: root
    spacing: 9
    // Memory shown as an amount needs a wider value column.
    readonly property int valueWidth: Cfg.ramUsage ? 58 : 32

    component Meter: Item {
        id: meter
        property string icon
        property string label
        // 0 to 1.
        property real value
        property color barColor: Theme.primary
        // Degrees; below zero there is no reading.
        property int temperature: -1
        property int valueWidth: root.valueWidth
        property string valueText: Math.round(fraction * 100) + "%"
        readonly property real fraction: Math.max(0, Math.min(1, value))
        width: parent.width
        height: 26

        Rectangle {
            id: badge
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            radius: 13
            color: "transparent"
            border.width: 1
            border.color: Theme.outline
            Text {
                anchors.centerIn: parent
                text: meter.icon
                color: meter.barColor
                font.family: Theme.fontIcons
                font.pixelSize: 15
            }
        }
        Text {
            id: name
            anchors.left: badge.right
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            text: meter.label
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.letterSpacing: Theme.labelSpacing
        }
        Rectangle {
            id: bar
            anchors.left: name.right
            anchors.right: amount.left
            anchors.leftMargin: 4
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Theme.surfaceHigh
            Rectangle {
                // Never shorter than a dot.
                width: Math.max(bar.height, bar.width * meter.fraction)
                height: bar.height
                radius: bar.radius
                color: meter.barColor
                Behavior on width { NumberAnimation { duration: Theme.durLong; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }
                Behavior on color { ColorAnimation { duration: Theme.durMedium } }
            }
        }
        Text {
            id: amount
            anchors.right: heat.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: meter.valueWidth
            horizontalAlignment: Text.AlignRight
            text: meter.valueText
            color: Theme.fg
            font.family: Theme.fontDots
            font.pixelSize: 14
            font.weight: Font.Bold
        }
        // Keeps its width while hidden so the bars line up.
        Row {
            id: heat
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            spacing: 1
            visible: meter.temperature >= 0
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "local_fire_department"
                color: Theme.primary
                font.family: Theme.fontIcons
                font.pixelSize: 12
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: meter.temperature + "°"
                color: Theme.primary
                font.family: Theme.fontDots
                font.pixelSize: 13
                font.weight: Font.Bold
            }
        }
    }

    Meter {
        icon: "memory"
        label: "CPU"
        value: SysInfo.cpu / 100
        temperature: SysInfo.cpuTemp
        barColor: SysInfo.cpu > 85 ? Theme.alert : Theme.primary
    }
    Meter {
        icon: "database"
        label: "RAM"
        value: SysInfo.mem / 100
        valueText: Cfg.ramUsage ? SysInfo.memShort : Math.round(fraction * 100) + "%"
        barColor: SysInfo.mem > 85 ? Theme.alert : Theme.fgDim
    }
    // A discrete GPU that is suspended stays asleep and says so.
    Meter {
        visible: SysInfo.gpuAvailable
        icon: "developer_board"
        label: "GPU"
        value: SysInfo.gpuAsleep ? 0 : SysInfo.gpu / 100
        temperature: SysInfo.gpuAvailable && !SysInfo.gpuAsleep ? SysInfo.gpuTemp : -1
        valueWidth: SysInfo.gpuAsleep ? 66 : root.valueWidth
        valueText: SysInfo.gpuAsleep ? Cfg.t("GPU ASLEEP") : Math.round(fraction * 100) + "%"
        barColor: SysInfo.gpu > 85 ? Theme.alert : Theme.fgDim
    }
}
