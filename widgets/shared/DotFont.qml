import QtQuick

// The theme's dot-matrix face (Nothing Dots, SIL OFL 1.1; see fonts/NothingDots-OFL.txt).
// `light` has smaller dots for big numerals, where the regular dots would touch.
FontLoader {
    property bool light: false
    source: Qt.resolvedUrl(light ? "fonts/NothingDotsLight.ttf" : "fonts/NothingDots.ttf")
}
