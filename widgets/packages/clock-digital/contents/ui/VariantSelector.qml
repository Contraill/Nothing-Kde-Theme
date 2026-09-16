import QtQuick
import "../../../../shared" as Glassy
import QtQuick.Layouts
import org.kde.plasma.plasmoid

Item {
    id: selector

    required property QtObject colors

    Glassy.GlassySurface {
        anchors.fill: parent
        anchors.margins: 10
        backgroundColor: selector.colors.background
        foregroundColor: selector.colors.textPrimary

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Choose Style")
                font.pixelSize: 14
                font.weight: Font.Medium
                color: selector.colors.textSecondary
            }

            Item { Layout.fillHeight: true }

            Repeater {
                model: [
                    { label: i18n("Digital Clock"), variant: 0 },
                    { label: i18n("World Clock"), variant: 1 }
                ]

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: index > 0 ? 16 : 0
                    text: modelData.label
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: selector.colors.textPrimary

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Plasmoid.configuration.widgetVariant = modelData.variant
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: i18n("can be changed later in configuration")
                font.pixelSize: 10
                color: selector.colors.textMuted
                wrapMode: Text.WordWrap
            }
        }
    }
}
