import QtQuick
import "../../../../../shared" as Glassy
import QtQuick.Controls as QQC2
import QtQuick.Layouts

Item {
    id: root
    objectName: "datePages"
    required property QtObject colors
    property date today: new Date()
    property string numberFont: "serif"
    property string labelFont: "sans-serif"
    property var locale: Qt.locale()
    property int page: 0
    property date monthDate: new Date(today.getFullYear(), today.getMonth(), 1, 12)
    readonly property bool turning: turn.running
    readonly property int firstWeekday: locale.firstDayOfWeek % 7
    readonly property int offset: (monthDate.getDay() - firstWeekday + 7) % 7
    function t(tr, en) { return locale.name.indexOf("tr") === 0 ? tr : en }
    function togglePage() { if (!turning) turn.start() }
    function moveMonth(delta) { monthDate = new Date(monthDate.getFullYear(), monthDate.getMonth() + delta, 1, 12) }
    function dayAt(index) { return new Date(monthDate.getFullYear(), monthDate.getMonth(), index - offset + 1, 12) }
    function sameDate(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate() }

    SequentialAnimation {
        id: turn
        ParallelAnimation {
            NumberAnimation { target: face; property: "scale"; to: 0.94; duration: 140; easing.type: Easing.InCubic }
            NumberAnimation { target: face; property: "opacity"; to: 0; duration: 140 }
            NumberAnimation { target: fold; property: "peel"; to: 64; duration: 140 }
        }
        ScriptAction { script: root.page = 1 - root.page }
        ParallelAnimation {
            NumberAnimation { target: face; property: "scale"; to: 1; duration: 210; easing.type: Easing.OutCubic }
            NumberAnimation { target: face; property: "opacity"; to: 1; duration: 210 }
            NumberAnimation { target: fold; property: "peel"; to: 30; duration: 210 }
        }
    }
    Glassy.GlassySurface {
        id: card
        anchors.fill: parent; anchors.margins: 10
        backgroundColor: root.colors.background
        foregroundColor: root.colors.textPrimary
    }
    Item {
        id: face
        anchors.fill: card
        ColumnLayout {
            visible: root.page === 0
            anchors.fill: parent; anchors.margins: 10; spacing: -10
            Text {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                text: root.locale.toString(root.today, "ddd")
                font.family: root.labelFont; font.pixelSize: Math.min(face.width, face.height) * 0.12
                color: root.colors.accent
            }
            Text {
                Layout.fillWidth: true; Layout.fillHeight: true
                text: root.locale.toString(root.today, "d")
                font.family: root.numberFont; font.bold: true
                font.pixelSize: Math.min(face.width, face.height) * 0.7
                color: root.colors.textPrimary
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
        ColumnLayout {
            visible: root.page === 1
            anchors.fill: parent; anchors.margins: 12; anchors.bottomMargin: 32; spacing: 4
            RowLayout {
                Layout.fillWidth: true; spacing: 2
                QQC2.AbstractButton {
                    objectName: "calendarPrevious"
                    Layout.preferredWidth: 24; Layout.preferredHeight: 24
                    Accessible.name: root.t("Önceki ay", "Previous month")
                    onClicked: root.moveMonth(-1)
                    contentItem: Text { text: "‹"; color: root.colors.textPrimary; font.pixelSize: 22; horizontalAlignment: Text.AlignHCenter }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.locale.toString(root.monthDate, "MMMM yyyy")
                    color: root.colors.accent; font.family: root.labelFont
                    font.pixelSize: Math.max(10, Math.min(18, face.width * 0.055))
                    horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                }
                QQC2.AbstractButton {
                    objectName: "calendarNext"
                    Layout.preferredWidth: 24; Layout.preferredHeight: 24
                    Accessible.name: root.t("Sonraki ay", "Next month")
                    onClicked: root.moveMonth(1)
                    contentItem: Text { text: "›"; color: root.colors.textPrimary; font.pixelSize: 22; horizontalAlignment: Text.AlignHCenter }
                }
            }
            GridLayout {
                columns: 7; rowSpacing: 1; columnSpacing: 1
                Layout.fillWidth: true; Layout.fillHeight: true
                Repeater {
                    model: 7
                    Text {
                        required property int index
                        Layout.fillWidth: true
                        text: root.locale.standaloneDayName((root.firstWeekday + index) % 7, Locale.NarrowFormat)
                        color: root.colors.textSecondary; font.family: root.labelFont
                        font.pixelSize: Math.max(9, Math.min(13, face.width * 0.04))
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                Repeater {
                    model: 42
                    Item {
                        id: cell
                        required property int index
                        readonly property date day: root.dayAt(index)
                        readonly property bool isToday: root.sameDate(day, root.today)
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height); height: width; radius: width / 2
                            color: "transparent"; border.width: cell.isToday ? 1 : 0; border.color: root.colors.accent
                        }
                        Text {
                            anchors.centerIn: parent; text: cell.day.getDate()
                            font.family: root.labelFont; font.pixelSize: Math.max(9, Math.min(18, face.height * 0.065))
                            color: cell.isToday ? root.colors.accent : cell.day.getMonth() === root.monthDate.getMonth() ? root.colors.textPrimary : root.colors.textMuted
                        }
                    }
                }
            }
        }
    }
    Canvas {
        id: fold
        property real peel: 30
        anchors.right: card.right; anchors.bottom: card.bottom
        width: root.turning ? peel : flip.hovered ? 42 : 30; height: width
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset(); ctx.fillStyle = root.colors.pagePeel; ctx.beginPath()
            ctx.moveTo(16, 0); ctx.arcTo(0, 0, 0, 16, 16)
            ctx.lineTo(0, height - 4); ctx.quadraticCurveTo(0, height, 4, height - 4)
            ctx.lineTo(width - 4, 4); ctx.quadraticCurveTo(width, 0, width - 4, 0)
            ctx.closePath(); ctx.fill()
        }
        Connections { target: root.colors; function onPagePeelChanged() { fold.requestPaint() } }
    }
    QQC2.AbstractButton {
        id: flip
        objectName: "calendarFlip"
        anchors.right: card.right; anchors.bottom: card.bottom; width: 42; height: 42
        enabled: !root.turning
        Accessible.name: root.page === 0 ? root.t("Aylık takvimi göster", "Show monthly calendar") : root.t("Günü göster", "Show date")
        onClicked: root.togglePage()
        background: Rectangle { color: "transparent"; radius: 8; border.width: flip.visualFocus ? 1 : 0; border.color: root.colors.accent }
    }
}
