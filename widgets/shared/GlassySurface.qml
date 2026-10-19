// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami

// Desktop applets and their wallpaper share a single Plasma window. KWin's
// window blur-behind cannot sample that window's own wallpaper. Deliberately
// use translucency, not a wallpaper capture or a software blur shader.
Rectangle {
    id: surface
    property color backgroundColor: Kirigami.Theme.backgroundColor
    property color foregroundColor: Kirigami.Theme.textColor
    property real surfaceOpacity: 0.5
    property real cornerRadius: 20
    // On the wallpaper: no glass and no edge, only what sits on the card.
    property bool bare: false

    color: bare ? "transparent" : Qt.rgba(backgroundColor.r, backgroundColor.g, backgroundColor.b, surfaceOpacity)
    radius: Math.min(cornerRadius, width / 2, height / 2)
    border.width: bare ? 0 : 1
    border.color: Qt.rgba(foregroundColor.r, foregroundColor.g, foregroundColor.b, 0.12)
    antialiasing: true
    // Never apply opacity to the item: children (text, icons, controls) stay opaque.
}
