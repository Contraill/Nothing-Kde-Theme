// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// The style picker of every widget's settings page: a card per style with its
// miniature. `styles` lists {label, value} with either `source` and `props`
// (a live design and the sample values it shows) or `image` (a rendered
// preview, the -dark.png file; the -light.png one beside it in a light theme).
ColumnLayout {
    id: cards
    property var styles: []
    property int selected: -1
    property string title: i18n("Style:")
    // The page's theme choices, so the miniatures show them.
    property alias themeMode: cardColors.themeMode
    property alias useSystemAccent: cardColors.useSystemAccent
    property alias monochrome: cardColors.monochrome
    signal picked(int value)
    spacing: 6

    WidgetColors { id: cardColors }
    DotFont { id: dots }

    QQC2.Label {
        text: cards.title
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
                Item {
                    id: preview
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    height: 76
                    Image {
                        anchors.fill: parent
                        visible: !!card.modelData.image
                        source: card.modelData.image && cardColors.isLight ? String(card.modelData.image).replace(/-dark\.png$/, "-light.png") : card.modelData.image ?? ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                    Loader {
                        anchors.fill: parent
                        active: !!card.modelData.source
                        Component.onCompleted: if (active) setSource(card.modelData.source,
                            Object.assign({colors: cardColors, family: dots.name}, card.modelData.props || {}))
                        // The miniature fills its card, without the desktop margin.
                        onLoaded: if ("inset" in item) item.inset = 0
                    }
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
}
