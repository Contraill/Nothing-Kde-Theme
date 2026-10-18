import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "."
Item {
    id: root
    readonly property var player: Media.player
    readonly property bool active: player !== null

    readonly property bool isPlaying: (player?.playbackStatus ?? 0) === Mpris.PlaybackStatus.Playing
    readonly property string artUrl: player?.artUrl ?? ""
    readonly property string appIcon: player?.iconName ?? ""
    readonly property real length: (player?.length ?? 0) / 1000000
    readonly property real position: (player?.position ?? 0) / 1000000
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    Timer {
        interval: 1000
        running: root.active && root.isPlaying
        repeat: true
        onTriggered: root.player?.updatePosition()
    }

    component MediaToggle: Text {
        id: toggle
        property string icon: ""
        property bool on: false
        property string label: ""
        signal triggered
        text: toggle.icon
        color: toggle.on ? Theme.primary : Theme.fgDim
        font.family: Theme.fontIcons
        font.pixelSize: 15
        Accessible.role: Accessible.CheckBox
        Accessible.name: toggle.label
        Accessible.checked: toggle.on
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: toggle.triggered()
        }
    }

    function fmt(seconds) {
        if (!seconds || seconds < 0)
            return "0:00";
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    implicitHeight: 118
    Kirigami.ImageColors {
        id: paleta
        source: artImg.status === Image.Ready ? artImg : null
    }
    readonly property var tonos: {
        const p = paleta.palette;
        if (!p || p.length === 0)
            return [paleta.dominant, paleta.dominant, paleta.dominant];
        return [p[0].color, p[Math.min(1, p.length - 1)].color, p[Math.min(2, p.length - 1)].color];
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.shapeLg
        color: Theme.surfaceAlt
        clip: true
        antialiasing: true
        Item {
            id: liquido
            anchors.fill: parent
            anchors.margins: card.radius
            visible: root.artUrl !== ""
            opacity: 1.0

            component Mancha: Item {
                id: mancha
                property color tono: "#808080"
                property int periodo: 9000
                property real desdeX: 0
                property real hastaX: 0
                property real desdeY: 0
                property real hastaY: 0
                width: card.width * 1.4
                height: width
                Canvas {
                    id: lienzo
                    anchors.centerIn: parent
                    width: 220
                    height: 220
                    scale: mancha.width / width
                    smooth: true

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();

                        const r = width / 2;
                        const g = ctx.createRadialGradient(r, r, 0, r, r, r);
                        const c = mancha.tono;
                        for (var i = 0; i <= 24; i++) {
                            const t = i / 24;
                            g.addColorStop(t, Qt.rgba(c.r, c.g, c.b, 1 - Math.exp(-1.15 * (1 - t * t))));
                        }

                        ctx.fillStyle = g;
                        ctx.fillRect(0, 0, width, height);
                    }
                    Connections {
                        target: mancha
                        function onTonoChanged() {
                            lienzo.requestPaint();
                        }
                    }
                }
                SequentialAnimation on x {
                    running: liquido.visible
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: mancha.hastaX - mancha.width / 2
                        duration: mancha.periodo
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: mancha.desdeX - mancha.width / 2
                        duration: mancha.periodo
                        easing.type: Easing.InOutSine
                    }
                }
                SequentialAnimation on y {
                    running: liquido.visible
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: mancha.hastaY - mancha.height / 2
                        duration: mancha.periodo * 1.4
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: mancha.desdeY - mancha.height / 2
                        duration: mancha.periodo * 1.4
                        easing.type: Easing.InOutSine
                    }
                }
            }

            Mancha {
                tono: root.tonos[0]
                periodo: 9000
                desdeX: card.width * 0.15
                hastaX: card.width * 0.55
                desdeY: card.height * 0.15
                hastaY: card.height * 0.8
            }
            Mancha {
                tono: root.tonos[1]
                periodo: 12000
                desdeX: card.width * 0.75
                hastaX: card.width * 0.35
                desdeY: card.height * 0.85
                hastaY: card.height * 0.2
            }
            Mancha {
                tono: root.tonos[2]
                periodo: 15000
                desdeX: card.width * 0.45
                hastaX: card.width * 0.85
                desdeY: card.height * 0.35
                hastaY: card.height * 0.95
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            antialiasing: true
            color: Theme.surfaceAlt
            opacity: root.artUrl !== "" ? 0.45 : 1
        }
        Canvas {
            id: corners
            anchors.fill: parent
            readonly property color surround: Theme.surface
            readonly property real cornerRadius: card.radius
            onSurroundChanged: requestPaint()
            onCornerRadiusChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const r = cornerRadius;
                const boxes = [[0, 0, r, r], [width-r, 0, width-r, r],
                               [0, height-r, r, height-r], [width-r, height-r, width-r, height-r]];
                for (let i = 0; i < boxes.length; ++i) {
                    const c = boxes[i];
                    ctx.save();
                    ctx.beginPath(); ctx.rect(c[0], c[1], r, r); ctx.clip();
                    ctx.fillStyle = surround;
                    ctx.fillRect(c[0], c[1], r, r);
                    ctx.globalCompositeOperation = "destination-out";
                    ctx.beginPath(); ctx.arc(c[2], c[3], r, 0, 2 * Math.PI); ctx.fill();
                    ctx.restore();
                }
            }
        }
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
            width: 46
            height: 46
            Rectangle {
                anchors.fill: parent
                radius: Theme.shapeSm
                color: Theme.containerHighest
            }
            Image {
                id: artImg
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
                visible: artImg.status === Image.Ready
            }
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 26
                height: 26
                visible: artImg.status !== Image.Ready && root.appIcon !== ""
                source: root.appIcon
            }

            Text {
                anchors.centerIn: parent
                visible: artImg.status !== Image.Ready && root.appIcon === ""
                text: Icons.music
                color: Theme.fgVariant
                font.family: Theme.fontIcons
                font.pixelSize: 22
            }
        }

        Column {
            anchors.left: art.right
            anchors.leftMargin: 12
            anchors.right: controls.left
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
                text: root.player?.artist ?? ""
                color: Theme.fgVariant
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                elide: Text.ElideRight
                visible: text !== ""
            }
        }
        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: art.verticalCenter
            spacing: 2

            Repeater {
                model: 3

                Rectangle {
                    id: btn
                    required property int index
                    readonly property bool isPlay: index === 1

                    width: isPlay ? 40 : 32
                    height: isPlay ? 40 : 32
                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter

                    color: isPlay ? Theme.fg : bma.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)
                    opacity: root.active ? 1 : 0.38
                    scale: bma.pressed ? 0.94 : bma.containsMouse ? 1.08 : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durShort
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.durShort
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.emphasizedDecel
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (btn.index === 0)
                                return Icons.prev;
                            if (btn.index === 2)
                                return Icons.next;
                            return root.isPlaying ? Icons.pause : Icons.play;
                        }
                        color: btn.isPlay ? Theme.surface : Theme.fg
                        font.family: Theme.fontIcons
                        font.pixelSize: btn.isPlay ? 22 : 18
                    }

                    MouseArea {
                        id: bma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.active
                        onClicked: {
                            const p = root.player;
                            if (!p)
                                return;
                            if (btn.index === 1)
                                p.PlayPause();
                            else if (btn.index === 2)
                                p.Next();
                            else
                                p.Previous();
                        }
                    }
                }
            }
        }
        Item {
            id: wave
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.top: art.bottom
            anchors.topMargin: 8
            height: 30

            readonly property int barCount: 64
            readonly property real barW: width / barCount
            readonly property var pattern: {
                const title = root.player?.track ?? "";
                let seed = 0;
                for (var i = 0; i < title.length; i++)
                    seed = (seed * 31 + title.charCodeAt(i)) & 0x7fffffff;
                if (seed === 0)
                    seed = 12345;

                const out = [];
                for (var b = 0; b < barCount; b++) {
                    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
                    const r = (seed >>> 8) / 0x7fffff;
                    const env = Math.sin(Math.PI * (b + 0.5) / barCount);
                    out.push(0.18 + 0.82 * r * (0.45 + 0.55 * env));
                }
                return out;
            }

            Row {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: wave.barCount

                    Item {
                        required property int index
                        width: wave.barW
                        height: wave.height

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.max(1.5, wave.barW - 1.5)
                            height: Math.max(2, wave.height * (wave.pattern[index] ?? 0.3))
                            radius: width / 2
                            color: (index / wave.barCount) <= root.progress ? Theme.primary : Theme.containerHighest

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durShort
                                }
                            }
                        }
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.active && (root.player?.canSeek ?? false)
                onClicked: mouse => {
                    const p = root.player;
                    if (!p || root.length <= 0)
                        return;
                    const destino = (mouse.x / wave.width) * root.length;
                    p.Seek(Math.round((destino - root.position) * 1000000));
                    p.updatePosition();
                }
            }
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: root.fmt(root.position)
            color: Theme.fgDim
            font.family: Theme.fontDots
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        // Player picker, shown only when more than one application plays media.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            spacing: 4
            visible: Media.players.length > 1
            Repeater {
                model: Media.players
                Rectangle {
                    id: pick
                    required property var modelData
                    readonly property bool selected: Media.currentIndex === modelData.index
                    width: 22
                    height: 22
                    radius: 11
                    color: pick.selected ? Qt.alpha(Theme.fg, 0.18) : pickMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : "transparent"
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: pick.modelData.identity
                    Accessible.checked: pick.selected
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        source: pick.modelData.icon
                        fallback: "media-playback-start"
                        opacity: pick.selected ? 1 : 0.55
                    }
                    MouseArea {
                        id: pickMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Clicking the pinned player again returns to automatic selection.
                        onClicked: Media.select(pick.selected ? 0 : pick.modelData.index)
                    }
                }
            }
        }
        Row {
            anchors.right: lengthText.left
            anchors.rightMargin: 8
            anchors.verticalCenter: lengthText.verticalCenter
            spacing: 2
            MediaToggle {
                visible: root.active && (root.player?.shuffle ?? 0) !== Mpris.ShuffleStatus.Unknown
                icon: "shuffle"
                on: (root.player?.shuffle ?? 0) === Mpris.ShuffleStatus.On
                label: Cfg.t("SHUFFLE")
                onTriggered: Media.toggleShuffle()
            }
            MediaToggle {
                readonly property int loop: root.player?.loopStatus ?? 0
                visible: root.active && loop !== Mpris.LoopStatus.Unknown
                icon: loop === Mpris.LoopStatus.Track ? "repeat_one" : "repeat"
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
            text: root.fmt(root.length)
            color: Theme.fgDim
            font.family: Theme.fontDots
            font.pixelSize: 13
            font.weight: Font.Bold
        }
    }
}
