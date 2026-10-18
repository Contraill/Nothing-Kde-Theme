// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts

// A labelled row of dots filled to `percent`; the accent marks a high value.
ColumnLayout {
    id: meter
    required property QtObject colors
    property string label: ""
    property real percent: 0
    property string detail: ""
    property bool alert: percent >= 85
    spacing: 4
    DotFont { id: dotFont }
    RowLayout {
        Layout.fillWidth: true
        Text { text: meter.label; color: meter.colors.textSecondary; font.pixelSize: 11; font.letterSpacing: 1.5 }
        Item { Layout.fillWidth: true }
        Text { text: meter.detail; color: meter.colors.textMuted; font.pixelSize: 10 }
        Text { text: Math.round(meter.percent) + "%"; color: meter.alert ? meter.colors.accent : meter.colors.textPrimary; font.family: dotFont.name; font.pixelSize: 14 }
    }
    Row {
        id: dotsRow
        Layout.fillWidth: true
        Layout.preferredHeight: 5
        readonly property int count: 22
        spacing: (width - count * height) / (count - 1)
        Repeater {
            model: dotsRow.count
            Rectangle {
                required property int index
                width: dotsRow.height
                height: width
                radius: width / 2
                color: index < Math.round(meter.percent / 100 * dotsRow.count) ? (meter.alert ? meter.colors.accent : meter.colors.textPrimary) : meter.colors.divider
            }
        }
    }
}
