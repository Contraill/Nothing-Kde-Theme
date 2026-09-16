import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

import "../components" as Components

Item {
    id: root

    property Components.ModelInterface modelInterface: Components.ModelInterface {}

    // NotificationPopup already pauses expiration while the pointer is over the
    // window. Keeping these strongly typed avoids probing Loader.item for custom
    // members and preserves safe timer behavior for the compact skin.
    readonly property bool dragging: notificationIcon.dragging
    readonly property bool menuOpen: Boolean(bodyLabel.menuOpen)
    readonly property string hoveredLink: bodyLabel.hoveredLink ?? ""

    property bool lightMode: false
    property bool showTimeout: true
    readonly property color surface: root.lightMode ? "#f7f7f2" : "#0c0c0c"
    readonly property color surfaceAlt: root.lightMode ? "#ededE7" : "#151515"
    readonly property color textColor: root.lightMode ? "#151515" : "#f2f2ed"
    readonly property color mutedColor: root.lightMode ? "#676760" : "#9b9b94"
    readonly property color outlineColor: root.lightMode ? "#c9c9c1" : "#30302c"
    readonly property color accentColor: root.modelInterface.urgency === NotificationManager.Notifications.CriticalUrgency ? "#d71920" : root.textColor

    Kirigami.Theme.inherit: false
    Kirigami.Theme.backgroundColor: root.surface
    Kirigami.Theme.textColor: root.textColor
    Accessible.role: Accessible.Notification
    Accessible.name: root.modelInterface.applicationName + ": " + root.modelInterface.summary
    Accessible.description: root.modelInterface.accessibleDescription || root.modelInterface.body

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    Layout.fillWidth: true
    Layout.preferredWidth: Kirigami.Units.gridUnit * 17

    Rectangle {
        id: card
        z: -1
        anchors.fill: parent
        anchors.leftMargin: -root.modelInterface.popupLeftPadding
        anchors.rightMargin: -root.modelInterface.popupRightPadding
        anchors.topMargin: -root.modelInterface.popupTopPadding
        anchors.bottomMargin: -root.modelInterface.popupBottomPadding
        radius: 20
        color: root.surface
        border.width: 1
        border.color: root.outlineColor

        NothingGlyphEdgeLights {
            anchors.fill: parent
            lightMode: root.lightMode
            active: root.Window.window ? root.Window.window.visible : root.visible
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            NothingNotificationGlyph {
                Layout.alignment: Qt.AlignTop
                glyph: root.modelInterface.urgency === NotificationManager.Notifications.CriticalUrgency ? "critical" : (root.modelInterface.notificationType === NotificationManager.Notifications.JobType ? "job" : "notification")
                color: root.textColor
                accentColor: root.accentColor
                lit: root.Window.window ? root.Window.window.visible : root.visible
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: (root.modelInterface.applicationName || root.modelInterface.originName || "NOTIFICATION").toUpperCase()
                        color: root.mutedColor
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    visible: text.length > 0
                    text: root.modelInterface.summary
                    color: root.textColor
                    textFormat: Text.PlainText
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            QQC2.ToolButton {
                id: closeButton
                visible: root.modelInterface.closable || root.modelInterface.dismissable
                Layout.alignment: Qt.AlignTop
                implicitWidth: 28
                implicitHeight: 28
                Accessible.name: root.modelInterface.dismissable ? qsTr("Dismiss notification") : qsTr("Close notification")
                contentItem: Text {
                    text: "×"
                    font.pixelSize: 22
                    color: closeButton.hovered ? root.textColor : root.mutedColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 14
                    color: closeButton.hovered || closeButton.visualFocus ? root.surfaceAlt : "transparent"
                    border.width: closeButton.visualFocus ? 1 : 0
                    border.color: root.textColor
                }
                onClicked: {
                    if (root.modelInterface.dismissable)
                        root.modelInterface.dismissClicked();
                    else
                        root.modelInterface.closeClicked();
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.modelInterface.body.length > 0 || notificationIcon.visible
            spacing: 12

            QQC2.ScrollView {
                id: bodyScroll
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredHeight: Math.min(bodyLabel.implicitHeight, Kirigami.Units.gridUnit * 6)
                visible: root.modelInterface.body.length > 0
                clip: true
                contentWidth: availableWidth
                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                Components.Body {
                    id: bodyLabel
                    width: bodyScroll.availableWidth
                    modelInterface: root.modelInterface
                    color: root.mutedColor
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                }
            }

            Components.Icon {
                id: notificationIcon
                Layout.alignment: Qt.AlignRight
                modelInterface: root.modelInterface
            }
        }

        Components.FooterLoader {
            id: footerLoader
            Layout.fillWidth: true
            visible: item !== null
            modelInterface: root.modelInterface
            iconContainerItem: notificationIcon
        }

        // Timeout is deliberately a row of dots instead of a progress bar. The
        // currently alive fraction lights left-to-right and shrinks as the popup
        // approaches expiry, keeping the Nothing glyph language without adding bulk.
        Row {
            visible: root.showTimeout && root.modelInterface.timeout > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            spacing: 3

            Repeater {
                model: 24

                Rectangle {
                    required property int index
                    width: 2
                    height: 2
                    radius: 1
                    color: root.accentColor
                    opacity: {
                        if (root.modelInterface.timeout <= 0) {
                            return index < 2 ? 0.7 : 0.16;
                        }
                        const fraction = Math.max(0, Math.min(1, root.modelInterface.remainingTime / root.modelInterface.timeout));
                        return index < Math.ceil(24 * fraction) ? 0.65 : 0.1;
                    }
                }
            }
        }
    }
}
