// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

// First-run style choice for widgets with several layouts. `variants` is a
// list of names; picking one emits chosen(index).
Item {
    id: picker
    required property QtObject colors
    property var variants: []
    signal chosen(int index)

    GlassySurface {
        id: card
        anchors.fill: parent
        anchors.margins: 10
        backgroundColor: picker.colors.background
        foregroundColor: picker.colors.textPrimary
    }
    ColumnLayout {
        anchors.centerIn: card
        width: card.width - 32
        spacing: 8
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Choose a style")
            font.pixelSize: 12
            font.letterSpacing: 1.2
            color: picker.colors.textSecondary
        }
        Repeater {
            model: picker.variants
            QQC2.AbstractButton {
                id: option
                required property string modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                onClicked: picker.chosen(index)
                background: Rectangle {
                    radius: height / 2
                    color: option.hovered ? picker.colors.alpha(picker.colors.textPrimary, 0.14) : picker.colors.alpha(picker.colors.textPrimary, 0.06)
                }
                contentItem: Text {
                    text: option.modelData
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    color: picker.colors.textPrimary
                }
            }
        }
        Text {
            Layout.fillWidth: true
            text: i18n("You can change it later in the settings.")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.pixelSize: 10
            color: picker.colors.textMuted
        }
    }
}
