pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import "."

ColumnLayout {
    id: root
    spacing: 10
    property real hue: 0
    property real saturation: 1
    property real brightness: 1
    readonly property color selectedColor: Qt.hsva(hue, saturation, brightness, 1)
    readonly property bool dragging: colorMouse.pressed || hueSlider.pressed
    signal edited()
    function setColor(value: color): void {
        hue = Math.max(0, value.hsvHue);
        saturation = value.hsvSaturation;
        brightness = value.hsvValue;
    }
    function selectPoint(x: real, y: real): void {
        saturation = Math.max(0, Math.min(1, x / field.width));
        brightness = 1 - Math.max(0, Math.min(1, y / field.height));
        edited()
    }
    Rectangle {
        id: field
        objectName: "colorSaturationValue"
        Layout.fillWidth: true
        Layout.preferredHeight: 110
        radius: Theme.shapeMd
        clip: true
        color: Qt.hsva(root.hue, 1, 1, 1)
        activeFocusOnTab: true
        Accessible.role: Accessible.Slider
        Accessible.name: Cfg.t("COLOR SATURATION VALUE")
        Accessible.description: Cfg.t("COLOR ARROW HELP")
        Keys.onLeftPressed: { root.saturation = Math.max(0, root.saturation - 0.02); root.edited(); }
        Keys.onRightPressed: { root.saturation = Math.min(1, root.saturation + 0.02); root.edited(); }
        Keys.onUpPressed: { root.brightness = Math.min(1, root.brightness + 0.02); root.edited(); }
        Keys.onDownPressed: { root.brightness = Math.max(0, root.brightness - 0.02); root.edited(); }
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "white" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: "black" }
            }
        }
        Rectangle {
            width: 12; height: 12; radius: 6
            x: Math.max(1, Math.min(field.width - width - 1, root.saturation * field.width - width / 2))
            y: Math.max(1, Math.min(field.height - height - 1, (1 - root.brightness) * field.height - height / 2))
            color: root.selectedColor
            border.width: 2; border.color: root.brightness > 0.7 ? "#151515" : "white"
        }
        MouseArea {
            id: colorMouse
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            onPressed: mouse => { field.forceActiveFocus(); root.selectPoint(mouse.x, mouse.y); }
            onPositionChanged: mouse => { if (pressed) root.selectPoint(mouse.x, mouse.y); }
        }
        Rectangle {
            anchors.fill: parent; radius: parent.radius; color: "transparent"
            border.width: field.activeFocus ? 2 : 1
            border.color: field.activeFocus ? Theme.primary : Theme.outline
        }
    }
    QQC2.Slider {
        id: hueSlider
        objectName: "colorHue"
        Layout.fillWidth: true
        Layout.preferredHeight: 24
        Accessible.name: Cfg.t("COLOR HUE")
        from: 0; to: 1; stepSize: 0.005
        value: root.hue
        onMoved: { root.hue = value; root.edited(); }
        background: Rectangle {
            x: hueSlider.leftPadding
            y: (hueSlider.height - height) / 2
            width: hueSlider.availableWidth; height: 12; radius: 6
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#ff0000" }
                GradientStop { position: 0.1667; color: "#ffff00" }
                GradientStop { position: 0.3333; color: "#00ff00" }
                GradientStop { position: 0.5; color: "#00ffff" }
                GradientStop { position: 0.6667; color: "#0000ff" }
                GradientStop { position: 0.8333; color: "#ff00ff" }
                GradientStop { position: 1; color: "#ff0000" }
            }
        }
        handle: Rectangle {
            x: hueSlider.leftPadding + hueSlider.visualPosition * (hueSlider.availableWidth - width)
            y: (hueSlider.height - height) / 2
            width: 18; height: 18; radius: 9
            color: Qt.hsva(root.hue, 1, 1, 1)
            border.width: 2; border.color: Theme.fg
        }
    }
}
