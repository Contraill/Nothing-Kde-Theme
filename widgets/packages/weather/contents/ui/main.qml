// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"

// Weather from Open-Meteo in four layouts; the pictures are dot glyphs.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }
    Glassy.DotFont { id: dots }
    Glassy.DotFont { id: bigDots; light: true }

    readonly property int variant: Plasmoid.configuration.widgetVariant
    WeatherService {
        id: weather
        location: Plasmoid.configuration.location
        fahrenheit: Plasmoid.configuration.temperatureUnit === 1
    }
    readonly property bool ready: !isNaN(weather.temperature)
    function degrees(value) { return isNaN(value) ? "–" : Math.round(value) + "°"; }
    function upper(text) { return text.toLocaleUpperCase(Qt.locale().name); }
    readonly property string glyph: weather.glyph(weather.code, weather.night)
    readonly property string status: weather.error || (ready ? weather.condition(weather.code) : i18n("Loading…"))

    component Round: Glassy.GlassySurface {
        cornerRadius: Math.min(width, height) / 2
        backgroundColor: nColors.background
        foregroundColor: nColors.textPrimary
    }

    fullRepresentation: Item {
        id: frame
        readonly property bool wide: root.variant === 3
        Layout.preferredWidth: wide ? 260 : 220
        Layout.preferredHeight: wide ? 96 : 220
        Layout.minimumWidth: wide ? 180 : 150
        Layout.minimumHeight: wide ? 72 : 150

        Glassy.VariantPicker {
            anchors.fill: parent
            visible: root.variant < 0
            colors: nColors
            variants: [i18n("Full"), i18n("Pill and circles"), i18n("Circle"), i18n("Pill")]
            onChosen: index => Plasmoid.configuration.widgetVariant = index
        }

        // 0: the full card; a click shows the next hours.
        Item {
            id: full
            anchors.fill: parent
            anchors.margins: 10
            visible: root.variant === 0
            property bool hoursPage: false
            Glassy.GlassySurface {
                anchors.fill: parent
                backgroundColor: nColors.background
                foregroundColor: nColors.textPrimary
            }
            MouseArea { anchors.fill: parent; onClicked: full.hoursPage = !full.hoursPage }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                visible: !full.hoursPage
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: root.upper(weather.place)
                    color: nColors.accent
                    font.family: dots.name
                    font.pixelSize: Math.max(11, full.height * 0.08)
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text {
                        text: root.degrees(weather.temperature)
                        color: nColors.textPrimary
                        font.family: bigDots.name
                        font.pixelSize: full.height * 0.3
                    }
                    Item { Layout.fillWidth: true }
                    Glassy.DotGlyph {
                        Layout.preferredWidth: full.width * 0.34
                        Layout.preferredHeight: full.width * 0.3
                        name: root.glyph
                        color: nColors.textPrimary
                        accentColor: nColors.accent
                        visible: root.ready
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.status
                    color: nColors.textSecondary
                    font.pixelSize: Math.max(11, full.height * 0.07)
                    elide: Text.ElideRight
                }
                Text {
                    text: "↑ " + root.degrees(weather.high) + "   ↓ " + root.degrees(weather.low)
                    color: nColors.textSecondary
                    font.family: dots.name
                    font.pixelSize: Math.max(11, full.height * 0.07)
                }
            }
            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                visible: full.hoursPage
                spacing: 4
                Repeater {
                    model: weather.hours.slice(0, 5)
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: String(modelData.hour).padStart(2, "0")
                            color: nColors.textMuted
                            font.family: dots.name
                            font.pixelSize: 11
                        }
                        Glassy.DotGlyph {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: full.width / 7
                            Layout.preferredHeight: full.width / 8
                            name: weather.glyph(modelData.code, modelData.night)
                            color: nColors.textPrimary
                            accentColor: nColors.accent
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.degrees(modelData.temperature)
                            color: nColors.textPrimary
                            font.family: dots.name
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }

        // 1: a pill with the sky over two circles, temperature and range.
        Item {
            anchors.fill: parent
            anchors.margins: 10
            visible: root.variant === 1
            readonly property real gap: 8
            Glassy.GlassySurface {
                id: pill
                width: parent.width
                height: (parent.height - parent.gap) / 2
                cornerRadius: height / 2
                backgroundColor: nColors.background
                foregroundColor: nColors.textPrimary
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: height * 0.3
                    anchors.rightMargin: height * 0.3
                    spacing: 10
                    Glassy.DotGlyph {
                        Layout.preferredWidth: pill.height * 0.6
                        Layout.preferredHeight: pill.height * 0.5
                        name: root.glyph
                        color: nColors.textPrimary
                        accentColor: nColors.accent
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.status
                        color: nColors.textPrimary
                        font.pixelSize: Math.max(11, pill.height * 0.17)
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }
            Round {
                id: left
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: (parent.width - parent.gap) / 2
                height: Math.min(width, pill.height)
                Text {
                    anchors.centerIn: parent
                    text: root.degrees(weather.temperature)
                    color: nColors.textPrimary
                    font.family: bigDots.name
                    font.pixelSize: parent.height * 0.34
                }
            }
            Round {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: left.width
                height: left.height
                Column {
                    anchors.centerIn: parent
                    Text { text: "↑ " + root.degrees(weather.high); color: nColors.textPrimary; font.family: dots.name; font.pixelSize: left.height * 0.16 }
                    Text { text: "↓ " + root.degrees(weather.low); color: nColors.textSecondary; font.family: dots.name; font.pixelSize: left.height * 0.16 }
                }
            }
        }

        // 2: a circle; a click steps through sky, temperature and range.
        Round {
            id: circle
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) - 20
            height: width
            visible: root.variant === 2
            property int page: 0
            MouseArea { anchors.fill: parent; onClicked: circle.page = (circle.page + 1) % 3 }
            Glassy.DotGlyph {
                anchors.centerIn: parent
                width: parent.width * 0.55
                height: parent.height * 0.45
                visible: circle.page === 0
                name: root.glyph
                color: nColors.textPrimary
                accentColor: nColors.accent
            }
            Text {
                anchors.centerIn: parent
                visible: circle.page === 1
                text: root.degrees(weather.temperature)
                color: nColors.textPrimary
                font.family: bigDots.name
                font.pixelSize: parent.height * 0.3
            }
            Column {
                anchors.centerIn: parent
                visible: circle.page === 2
                Text { text: "↑ " + root.degrees(weather.high); color: nColors.textPrimary; font.family: dots.name; font.pixelSize: circle.height * 0.13 }
                Text { text: "↓ " + root.degrees(weather.low); color: nColors.textSecondary; font.family: dots.name; font.pixelSize: circle.height * 0.13 }
            }
            // Which page is showing, as three small dots.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.1
                spacing: 4
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: 5; height: 5; radius: 2.5
                        color: index === circle.page ? nColors.accent : nColors.divider
                    }
                }
            }
        }

        // 3: one pill, sky, temperature and city.
        Glassy.GlassySurface {
            anchors.fill: parent
            anchors.margins: 10
            visible: root.variant === 3
            cornerRadius: height / 2
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: parent.height * 0.3
                anchors.rightMargin: parent.height * 0.35
                spacing: 12
                Glassy.DotGlyph {
                    Layout.preferredWidth: parent.height * 0.62
                    Layout.preferredHeight: parent.height * 0.5
                    name: root.glyph
                    color: nColors.textPrimary
                    accentColor: nColors.accent
                }
                Text {
                    text: root.degrees(weather.temperature)
                    color: nColors.textPrimary
                    font.family: bigDots.name
                    font.pixelSize: parent.height * 0.36
                }
                Column {
                    Layout.fillWidth: true
                    Text { width: parent.width; text: root.upper(weather.place); color: nColors.accent; font.family: dots.name; font.pixelSize: Math.max(12, frame.height * 0.13); elide: Text.ElideRight }
                    Text { width: parent.width; text: root.status; color: nColors.textSecondary; font.pixelSize: Math.max(11, frame.height * 0.11); elide: Text.ElideRight }
                }
            }
        }
    }
}
