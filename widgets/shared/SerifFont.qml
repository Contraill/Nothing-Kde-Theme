import QtQuick

// Nothing Serif (SIL OFL 1.1, a static Fraunces; see fonts/NothingSerif-OFL.txt).
FontLoader {
    property bool light: false
    source: Qt.resolvedUrl(light ? "fonts/NothingSerifLight.ttf" : "fonts/NothingSerif.ttf")
}
