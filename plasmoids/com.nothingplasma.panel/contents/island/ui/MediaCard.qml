// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "."

// The expanded island's player card: cover, track, transport, a dotted
// waveform that seeks, shuffle and repeat, and chips to choose the player
// when several are open. With a cover, its colours drift behind the card.
Item {
    id: root

    readonly property var player: Media.player
    readonly property bool active: player !== null
    readonly property bool isPlaying: (player?.playbackStatus ?? 0) === Mpris.PlaybackStatus.Playing
    readonly property string artUrl: Media.artUrl
    // MPRIS counts microseconds.
    readonly property real length: (player?.length ?? 0) / 1000000
    readonly property real position: (player?.position ?? 0) / 1000000
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    // Players do not announce their position while playing; ask once a second.
    Timer {
        interval: 1000
        running: root.active && root.isPlaying
        repeat: true
        onTriggered: root.player?.updatePosition()
    }

    function clock(seconds) {
        if (!(seconds > 0)) return "0:00";
        const s = Math.floor(seconds % 60);
        return Math.floor(seconds / 60) + ":" + (s < 10 ? "0" : "") + s;
    }

    // Room for the player chips once more than one application plays media.
    readonly property int pickerHeight: Media.players.length > 1 ? 32 : 0
    implicitHeight: 118 + pickerHeight

    // Three colours from the cover for the background glow.
    Kirigami.ImageColors {
        id: coverColours
        source: coverSample.status === Image.Ready ? coverSample : null
    }
    readonly property var glowColours: {
        const swatches = coverColours.palette;
        if (!swatches || swatches.length === 0)
            return [coverColours.dominant, coverColours.dominant, coverColours.dominant];
        return [0, 1, 2].map(i => swatches[Math.min(i, swatches.length - 1)].color);
    }

    // A soft disc of colour that drifts between two points and back.
    component Glow: Shape {
        id: glow
        property color colour: "#808080"
        property int period: 9000
        property point from
        property point to
        width: card.width * 1.4
        height: width
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: glow.width / 2
                centerY: glow.height / 2
                centerRadius: glow.width / 2
                focalX: centerX
                focalY: centerY
                // Opaque in the middle, fading out smoothly towards the rim.
                GradientStop { position: 0.0; color: Qt.alpha(glow.colour, 0.68) }
                GradientStop { position: 0.35; color: Qt.alpha(glow.colour, 0.63) }
                GradientStop { position: 0.6; color: Qt.alpha(glow.colour, 0.46) }
                GradientStop { position: 0.8; color: Qt.alpha(glow.colour, 0.27) }
                GradientStop { position: 1.0; color: Qt.alpha(glow.colour, 0) }
            }
            PathAngleArc {
                centerX: glow.width / 2
                centerY: glow.height / 2
                radiusX: glow.width / 2
                radiusY: glow.height / 2
                sweepAngle: 360
            }
        }
        SequentialAnimation on x {
            running: glow.visible
            loops: Animation.Infinite
            NumberAnimation { to: glow.to.x - glow.width / 2; duration: glow.period; easing.type: Easing.InOutSine }
            NumberAnimation { to: glow.from.x - glow.width / 2; duration: glow.period; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on y {
            running: glow.visible
            loops: Animation.Infinite
            NumberAnimation { to: glow.to.y - glow.height / 2; duration: glow.period * 1.4; easing.type: Easing.InOutSine }
            NumberAnimation { to: glow.from.y - glow.height / 2; duration: glow.period * 1.4; easing.type: Easing.InOutSine }
        }
    }

    // Shuffle and repeat: icon-only, the accent while on.
    component Toggle: Text {
        id: toggle
        property bool on: false
        property string label: ""
        signal triggered
        color: on ? Theme.primary : Theme.fgDim
        font.family: Theme.fontIcons
        font.pixelSize: 15
        Accessible.role: Accessible.CheckBox
        Accessible.name: label
        Accessible.checked: on
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: toggle.triggered()
        }
    }

    component TransportButton: Rectangle {
        id: button
        property string icon: ""
        // The middle button is larger and filled.
        property bool primary: false
        signal clicked
        anchors.verticalCenter: parent.verticalCenter
        width: primary ? 40 : 32
        height: width
        radius: width / 2
        color: primary ? Theme.fg : Qt.alpha(Theme.fg, area.containsMouse ? Theme.stateHover : 0)
        opacity: root.active ? 1 : 0.38
        scale: area.pressed ? 0.94 : area.containsMouse ? 1.08 : 1.0
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Behavior on scale { NumberAnimation { duration: Theme.durShort; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasizedDecel } }
        Text {
            anchors.centerIn: parent
            text: button.icon
            color: button.primary ? Theme.surface : Theme.fg
            font.family: Theme.fontIcons
            font.pixelSize: button.primary ? 22 : 18
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: root.active
            onClicked: button.clicked()
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.shapeLg
        color: Theme.surfaceAlt
        clip: true
        antialiasing: true

        Item {
            id: glows
            anchors.fill: parent
            anchors.margins: card.radius
            visible: root.artUrl !== ""
            Glow { colour: root.glowColours[0]; period: 9000; from: Qt.point(card.width * 0.15, card.height * 0.15); to: Qt.point(card.width * 0.55, card.height * 0.8) }
            Glow { colour: root.glowColours[1]; period: 12000; from: Qt.point(card.width * 0.75, card.height * 0.85); to: Qt.point(card.width * 0.35, card.height * 0.2) }
            Glow { colour: root.glowColours[2]; period: 15000; from: Qt.point(card.width * 0.45, card.height * 0.35); to: Qt.point(card.width * 0.85, card.height * 0.95) }
        }
        // Veils the glow so the text stays readable.
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            antialiasing: true
            color: Theme.surfaceAlt
            opacity: root.artUrl !== "" ? 0.45 : 1
        }
        // clip is rectangular: paint the island's colour into the four corners.
        Shape {
            anchors.fill: parent
            visible: glows.visible
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillColor: Theme.surface
                fillRule: ShapePath.OddEvenFill
                PathRectangle { width: card.width; height: card.height }
                PathRectangle { width: card.width; height: card.height; radius: card.radius }
            }
        }

        // The cover and titles open the player's window.
        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: art.bottom
            anchors.right: controls.left
            anchors.bottomMargin: -2
            enabled: root.active && (root.player?.canRaise ?? false)
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: Cfg.t("OPEN PLAYER")
            onClicked: Media.raise()
        }
        Item {
            id: art
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
            anchors.topMargin: 10 + root.pickerHeight
            width: 46
            height: 46
            Rectangle {
                anchors.fill: parent
                radius: Theme.shapeSm
                color: Theme.surfaceHigh
            }
            // Hidden: the colour sampler and the readiness check for the cover.
            Image {
                id: coverSample
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: 92
                sourceSize.height: 92
                visible: false
            }
            Kirigami.ShadowedImage {
                anchors.fill: parent
                radius: Theme.shapeSm
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 92
                sourceSize.height: 92
                visible: coverSample.status === Image.Ready
            }
            // No cover (a browser video, say): a note, not the app's colourful icon.
            Text {
                anchors.centerIn: parent
                visible: coverSample.status !== Image.Ready
                text: Icons.music
                color: Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 22
            }
        }
        Column {
            anchors.left: art.right
            anchors.right: controls.left
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.verticalCenter: art.verticalCenter
            spacing: 1
            Text {
                width: parent.width
                text: root.player?.track || Cfg.t("Nothing playing")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodyMedium
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: root.player?.artist ?? ""
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                elide: Text.ElideRight
            }
        }
        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: art.verticalCenter
            spacing: 2
            TransportButton { icon: Icons.prev; onClicked: root.player?.Previous() }
            TransportButton { icon: root.isPlaying ? Icons.pause : Icons.play; primary: true; onClicked: root.player?.PlayPause() }
            TransportButton { icon: Icons.next; onClicked: root.player?.Next() }
        }

        // Not the audio: bars drawn from a hash of the title, taller mid-track,
        // lit up to the playback position. A click seeks there.
        Item {
            id: wave
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.top: art.bottom
            anchors.topMargin: 8
            height: 30
            readonly property int count: 64
            readonly property real step: width / count
            readonly property var heights: {
                // FNV-1a of the title seeds a xorshift sequence.
                let h = 2166136261;
                for (const ch of root.player?.track ?? "")
                    h = Math.imul(h ^ ch.charCodeAt(0), 16777619) >>> 0;
                h = h || 1;
                const out = [];
                for (let i = 0; i < count; ++i) {
                    h ^= h << 13; h ^= h >>> 17; h ^= h << 5; h >>>= 0;
                    const swell = Math.sin(Math.PI * (i + 0.5) / count);
                    out.push(0.18 + 0.82 * (h / 4294967296) * (0.45 + 0.55 * swell));
                }
                return out;
            }
            Repeater {
                model: wave.count
                Rectangle {
                    required property int index
                    x: index * wave.step + (wave.step - width) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(1.5, wave.step - 1.5)
                    height: Math.max(2, wave.height * wave.heights[index])
                    radius: width / 2
                    color: index / wave.count <= root.progress ? Theme.primary : Theme.surfaceHigh
                    Behavior on color { ColorAnimation { duration: Theme.durShort } }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.active && (root.player?.canSeek ?? false) && root.length > 0
                // Seek is relative, in microseconds.
                onClicked: mouse => {
                    root.player.Seek(Math.round((mouse.x / wave.width * root.length - root.position) * 1000000));
                    root.player.updatePosition();
                }
            }
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: root.clock(root.position)
            color: Theme.fgDim
            font.family: Theme.fontDots
            font.pixelSize: 13
            font.weight: Font.Bold
        }
        Row {
            anchors.right: lengthText.left
            anchors.rightMargin: 8
            anchors.verticalCenter: lengthText.verticalCenter
            spacing: 2
            Toggle {
                readonly property int shuffle: root.player?.shuffle ?? Mpris.ShuffleStatus.Unknown
                visible: root.active && shuffle !== Mpris.ShuffleStatus.Unknown
                text: "shuffle"
                on: shuffle === Mpris.ShuffleStatus.On
                label: Cfg.t("SHUFFLE")
                onTriggered: Media.toggleShuffle()
            }
            Toggle {
                readonly property int loop: root.player?.loopStatus ?? Mpris.LoopStatus.Unknown
                visible: root.active && loop !== Mpris.LoopStatus.Unknown
                text: loop === Mpris.LoopStatus.Track ? "repeat_one" : "repeat"
                on: loop === Mpris.LoopStatus.Playlist || loop === Mpris.LoopStatus.Track
                label: Cfg.t("REPEAT")
                onTriggered: Media.cycleLoop()
            }
        }
        Text {
            id: lengthText
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: root.clock(root.length)
            color: Theme.fgDim
            font.family: Theme.fontDots
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // The filled chip is the player the card controls. Clicking another
        // pins it; clicking the pinned one follows the active player again.
        Flickable {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            height: 24
            visible: root.pickerHeight > 0
            contentWidth: chips.width
            clip: true
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            Row {
                id: chips
                spacing: 6
                Repeater {
                    model: Media.players
                    Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool selected: Media.controls(modelData)
                        readonly property bool pinned: Media.currentIndex === modelData.index
                        width: chipContent.implicitWidth + 20
                        height: 24
                        radius: 12
                        color: selected ? Theme.inverted : chipArea.containsMouse ? Theme.surfaceHigh : Qt.alpha(Theme.fg, 0.08)
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: modelData.identity
                        Accessible.checked: selected
                        Behavior on color { ColorAnimation { duration: Theme.durShort } }
                        Row {
                            id: chipContent
                            anchors.centerIn: parent
                            spacing: 6
                            Kirigami.Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                source: chip.modelData.icon
                                fallback: "applications-multimedia"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, 120)
                                // Application names keep their own spelling.
                                text: chip.modelData.identity
                                color: chip.selected ? Theme.invertedFg : Theme.fgDim
                                font.family: Theme.font
                                font.pixelSize: Theme.labelMedium
                                elide: Text.ElideRight
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: chip.pinned
                                text: "keep"
                                color: chip.selected ? Theme.invertedFg : Theme.fgDim
                                font.family: Theme.fontIcons
                                font.pixelSize: 12
                            }
                        }
                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.select(chip.pinned ? 0 : chip.modelData.index)
                        }
                    }
                }
            }
        }
    }
}
