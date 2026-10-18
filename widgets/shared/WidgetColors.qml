// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    function alpha(c, value) { return Qt.rgba(c.r, c.g, c.b, value) }
    property int themeMode: 2 // Legacy preference: dark / light / system.
    property bool useSystemAccent: true
    readonly property bool useSystem: themeMode === 2
    readonly property color paletteBackground: Kirigami.Theme.backgroundColor
    readonly property color paletteText: Kirigami.Theme.textColor
    readonly property bool systemIsDark: (0.2126 * paletteBackground.r + 0.7152 * paletteBackground.g + 0.0722 * paletteBackground.b) < 0.5
    readonly property bool isLight: themeMode === 1 || (useSystem && !systemIsDark)
    // Explicit legacy mode overrides use the palette's contrasting pair, not
    // a second set of Nothing-specific light/dark colors.
    readonly property bool reversePalette: !useSystem && isLight === systemIsDark
    readonly property color background: reversePalette ? paletteText : paletteBackground
    readonly property color textPrimary: reversePalette ? paletteBackground : paletteText
    readonly property color surface: Qt.tint(background, alpha(textPrimary, 0.04))
    readonly property color textSecondary: Qt.tint(background, alpha(textPrimary, 0.72))
    readonly property color textMuted: Qt.tint(background, alpha(textPrimary, 0.60))
    readonly property color textDisabled: Qt.tint(background, alpha(textPrimary, 0.45))
    readonly property color textPlaceholder: textMuted
    readonly property color accent: useSystemAccent ? Kirigami.Theme.focusColor : "#ff4444"
    readonly property color accentSecondHand: useSystemAccent ? Kirigami.Theme.focusColor : "#D71921"
    // Readable ink on an accent fill.
    readonly property color accentText: (0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b) > 0.6 ? "#111111" : "#ffffff"
    readonly property color warning: Kirigami.Theme.neutralTextColor
    readonly property color error: Kirigami.Theme.negativeTextColor
    readonly property color divider: alpha(textPrimary, 0.12)
    readonly property color pagePeel: Qt.tint(background, alpha(textPrimary, 0.12))
    readonly property color indicatorActive: textPrimary
    readonly property color indicatorInactive: textDisabled
    readonly property color iconColor: textPrimary
    readonly property color borderLight: textSecondary
    readonly property color neutral: textSecondary
    readonly property color surfaceAlt: surface
    readonly property color surfaceGradient: surface
    readonly property color batteryBgFill: alpha(textPrimary, 0.025)
    readonly property color batteryProgressFill: alpha(textPrimary, 0.10)
    readonly property color batteryRingFill: alpha(textPrimary, 0.26)
}
