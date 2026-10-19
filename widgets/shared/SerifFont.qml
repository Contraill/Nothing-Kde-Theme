import QtQuick

// Nothing Serif (SIL OFL 1.1, a static Fraunces; see fonts/NothingSerif-OFL.txt).
// `small` is the text optical size, for labels and calendars at 9 to 18 px.
FontLoader {
    property bool light: false
    property bool small: false
    source: Qt.resolvedUrl(small ? "fonts/NothingSerifText.ttf" : light ? "fonts/NothingSerifLight.ttf" : "fonts/NothingSerif.ttf")
}
