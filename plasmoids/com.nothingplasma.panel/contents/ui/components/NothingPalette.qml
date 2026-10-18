import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

QtObject {
    id: root

    // Appearance is explicit and panel-local for reliable rendering. The theme
    // helper mirrors appearanceMode to all installed Nothing panels, so
    // they still switch as one shell without depending on palette propagation.
    property color accent: Kirigami.Theme.focusColor

    readonly property string configuredMode: String(Plasmoid.configuration?.appearanceMode || "dark")
    readonly property bool lightMode: root.configuredMode === "light"
        ? true
        : (root.configuredMode === "dark"
            ? false
            : Kirigami.Theme.backgroundColor.hslLightness > 0.62)

    readonly property color background: root.lightMode ? "#f1f1ed" : "#090909"
    readonly property color surface: root.lightMode ? "#fbfbf8" : "#111111"
    readonly property color surfaceAlt: root.lightMode ? "#e6e6e0" : "#181818"
    readonly property color elevated: root.lightMode ? "#dcdcd5" : "#202020"
    readonly property color text: root.lightMode ? "#151515" : "#f1f1eb"
    readonly property color mutedText: root.lightMode ? "#65655f" : "#a4a49d"
    readonly property color faintText: root.lightMode ? "#92928b" : "#6f6f69"
    readonly property color outline: root.lightMode ? "#c9c9c2" : "#2b2b28"
    readonly property color outlineStrong: root.lightMode ? "#a9a9a2" : "#41413d"
    readonly property color accentText: root.accent.hslLightness > 0.58 ? "#111111" : "#ffffff"
    readonly property color danger: root.accent
}
