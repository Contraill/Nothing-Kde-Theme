// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

// The day in large type; a click turns the page to the month, whose arrows
// step through months.
Item {
    id: page
    objectName: "datePage"
    required property QtObject colors
    property date today: new Date()
    property var locale: Qt.locale()
    property string numberFamily: ""
    property string labelFamily: ""
    property bool back: false
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    function flip() { back = !back; }
    function step(months) { month = new Date(month.getFullYear(), month.getMonth() + months, 1); }
    onBackChanged: if (!back) month = new Date(today.getFullYear(), today.getMonth(), 1)

    // Under everything else, so the month arrows keep their own clicks.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: page.flip()
    }
    Item {
        anchors.fill: parent
        opacity: page.back ? 0 : 1
        scale: page.back ? 0.94 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Text {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: parent.height * 0.08
            text: page.locale.toString(page.today, "ddd")
            color: page.colors.accent
            font.family: page.labelFamily
            font.pixelSize: parent.height * 0.13
        }
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: parent.height * 0.05
            text: page.today.getDate()
            color: page.colors.textPrimary
            font.family: page.numberFamily
            font.pixelSize: parent.height * 0.62
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 2
        opacity: page.back ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        RowLayout {
            Layout.fillWidth: true
            QQC2.AbstractButton {
                objectName: "previousMonth"
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                Accessible.name: i18n("Previous month")
                onClicked: page.step(-1)
                contentItem: Text { text: "‹"; color: page.colors.textPrimary; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: page.locale.toString(page.month, "MMMM yyyy")
                color: page.colors.accent
                font.family: page.labelFamily
                font.pixelSize: 13
            }
            QQC2.AbstractButton {
                objectName: "nextMonth"
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                Accessible.name: i18n("Next month")
                onClicked: page.step(1)
                contentItem: Text { text: "›"; color: page.colors.textPrimary; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }
        MonthGrid {
            objectName: "monthGrid"
            Layout.alignment: Qt.AlignHCenter
            colors: page.colors
            today: page.today
            locale: page.locale
            month: page.month
            numberFamily: page.labelFamily
            cell: Math.min((page.width - 20) / 7, (page.height - 46) / 7)
        }
    }
}
