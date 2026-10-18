// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "components"

// A photo in a rounded or pill frame, optionally grey and with a border.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }

    readonly property var config: Plasmoid.configuration
    // Earlier versions shipped other default files; they all mean the default.
    function imageUrl(path) {
        if (!path || path === "default/nothing.png" || path === "default/sample.jpeg")
            return Qt.resolvedUrl("../default/halftone.png");
        if (path.startsWith("/"))
            return "file://" + path;
        if (path.indexOf(":") > 0)
            return path;
        return Qt.resolvedUrl("../" + path);
    }

    fullRepresentation: Item {
        id: frame
        Layout.preferredWidth: 220
        Layout.preferredHeight: 220
        Layout.minimumWidth: 100
        Layout.minimumHeight: 100

        readonly property real border: root.config.borderEnabled ? Math.max(0, root.config.borderSize) : 0
        readonly property real outerRadius: root.config.pillShapeEnabled ? Math.min(width, height) / 2 - 10 : 22

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            radius: frame.outerRadius
            visible: frame.border > 0
            color: nColors.textPrimary
        }
        // The photo is masked to the frame's shape and optionally greyed in
        // one effect pass.
        Image {
            id: photo
            anchors.fill: parent
            anchors.margins: 10 + frame.border
            source: root.imageUrl(root.config.imagePath)
            fillMode: [Image.PreserveAspectCrop, Image.PreserveAspectFit, Image.Stretch][root.config.imageFillMode] ?? Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            visible: false
        }
        Rectangle {
            id: shape
            anchors.fill: photo
            radius: Math.max(0, frame.outerRadius - frame.border)
            visible: false
            layer.enabled: true
        }
        MultiEffect {
            anchors.fill: photo
            source: photo
            maskEnabled: true
            maskSource: shape
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            saturation: root.config.grayscaleEnabled ? -1 : 0
            visible: photo.status === Image.Ready
        }
        Column {
            anchors.centerIn: parent
            spacing: 8
            visible: photo.status === Image.Error
            Kirigami.Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "image-missing"
                implicitWidth: 32
                implicitHeight: 32
            }
            Text {
                text: i18n("The image could not be opened")
                color: nColors.textSecondary
                font.pixelSize: 12
            }
        }
    }
}
