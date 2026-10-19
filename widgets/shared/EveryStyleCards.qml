// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Settings cards for the styles adapted from EveryThing-UI, each a live
// miniature of its design. `styles` lists {label, value, source, props};
// `source` is the design's URL and `props` the sample values it shows.
ColumnLayout {
    id: cards
    property var styles: []
    property int selected: -1
    signal picked(int value)
    spacing: 6

    WidgetColors { id: cardColors }
    DotFont { id: dots }

    QQC2.Label {
        text: i18n("EveryThing-UI styles:")
        font.weight: Font.Medium
    }
    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: cards.styles
            Rectangle {
                id: card
                required property var modelData
                readonly property bool chosen: cards.selected === modelData.value
                width: 132
                height: 112
                radius: 10
                color: chosen ? Qt.alpha(Kirigami.Theme.highlightColor, 0.15) : "transparent"
                border.width: chosen ? 2 : 1
                border.color: chosen ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                Loader {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    height: 76
                    Component.onCompleted: setSource(card.modelData.source,
                        Object.assign({colors: cardColors, family: dots.name}, card.modelData.props || {}))
                }
                QQC2.Label {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: card.modelData.label
                    font.pointSize: 9
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cards.picked(card.modelData.value)
                }
            }
        }
    }
    QQC2.Label {
        Layout.fillWidth: true
        text: i18n("Designs adapted from EveryThing-UI by Prince-1652 (MIT).")
        wrapMode: Text.Wrap
        opacity: 0.7
        font.pointSize: 8
    }
}
