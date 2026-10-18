import QtQuick
import QtQuick.Controls as QQC2

Rectangle {
    id: root
    radius: Theme.shapeLg
    color: Theme.containerHigh
    readonly property var controls: Backend.controls
    property bool keyboardMode: false
    // One entry of controls.displays; null drives the built-in (primary) display.
    property var display: null
    signal requestDetails
    readonly property bool keyboardAvailable: controls?.keyboardBrightnessAvailable ?? false
    readonly property bool detailsAvailable: controls?.brightnessDetailsAvailable ?? keyboardAvailable
    readonly property bool available: keyboardMode ? keyboardAvailable : (controls?.brightnessAvailable ?? false)
    readonly property int percent: keyboardMode ? (controls?.keyboardBrightness ?? 0) : display ? display.percent : (controls?.brightness ?? 0)
    readonly property string title: keyboardMode ? Cfg.t("KEYBOARD BRIGHTNESS") : display ? display.label : Cfg.t("BRIGHTNESS")
    property int pendingValue: -1

    function flush() {
        update.stop();
        if (pendingValue < 0) return;
        const value = pendingValue;
        pendingValue = -1;
        if (!Backend.preview && available) {
            if (keyboardMode) controls.setKeyboardBrightness(value);
            else controls.setDisplayBrightness(value, display?.displayName ?? "");
        }
    }
    Timer { id: update; interval: 100; onTriggered: root.flush() }

    Text {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 8
        text: root.title
        color: root.available ? Theme.fg : Theme.fgFaint
        font.family: Theme.font
        font.pixelSize: Theme.bodySmall
        font.weight: Font.Medium
        font.letterSpacing: Theme.labelSpacing
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: label.verticalCenter
        text: root.available ? Math.round(slider.pressed ? slider.value : root.percent) + "%" : "—"
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: Theme.labelSmall
    }
    Text {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 9
        text: root.keyboardMode ? "keyboard" : "light_mode"
        color: root.available ? Theme.fgVariant : Theme.fgFaint
        font.family: Theme.fontIcons
        font.pixelSize: 16
    }
    QQC2.Slider {
        id: slider
        objectName: "brightnessSlider"
        anchors.left: icon.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: icon.verticalCenter
        height: 20
        padding: 0
        from: root.keyboardMode ? 0 : 1 // Only keyboard lighting can be switched fully off.
        to: 100
        stepSize: root.keyboardMode ? 100 / Math.max(1, root.controls?.keyboardBrightnessMax ?? 1) : 1
        snapMode: QQC2.Slider.SnapAlways
        Binding {
            target: slider
            property: "value"
            value: root.percent
            when: !slider.pressed
            restoreMode: Binding.RestoreNone
        }
        enabled: root.available
        Accessible.name: root.title
        Accessible.description: !root.keyboardMode && !root.display && root.detailsAvailable
            ? Cfg.t("BRIGHTNESS RIGHT CLICK") : root.keyboardMode ? Cfg.t("KEYBOARD BRIGHTNESS") : Cfg.t("BRIGHTNESS HELP")
        onMoved: {
            root.pendingValue = Math.round(value);
            if (!update.running) update.start();
        }
        onPressedChanged: if (!pressed) root.flush()
        background: Rectangle {
            y: (slider.height - height) / 2
            width: slider.availableWidth
            height: 6
            radius: 3
            color: Theme.containerHighest
            Rectangle {
                width: parent.width * slider.visualPosition
                height: parent.height
                radius: parent.radius
                color: root.available ? Theme.fg : Theme.outline
            }
        }
        handle: Rectangle {
            x: slider.visualPosition * (slider.availableWidth - width)
            y: (slider.height - height) / 2
            width: 10
            height: 10
            radius: 5
            color: Theme.fg
            visible: root.available && (slider.hovered || slider.pressed || slider.activeFocus)
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        enabled: !root.keyboardMode && !root.display && root.detailsAvailable
        onClicked: root.requestDetails()
    }
}
