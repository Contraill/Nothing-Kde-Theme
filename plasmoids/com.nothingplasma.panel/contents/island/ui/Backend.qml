pragma Singleton
import QtQuick
QtObject {
    property var trayHost: null
    property var controls: null
    property var appletItem: null
    property var stats: null
    property bool preview: false
    property bool expanded: false
    // Ask the panel to close the expanded island (e.g. after opening an app).
    signal dismissRequested()
}
