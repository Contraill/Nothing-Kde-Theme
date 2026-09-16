import QtQuick
import "."

Canvas {
    id: root
    implicitWidth: 18
    implicitHeight: 18
    property int strength: -1
    readonly property int level: strength >= 75 ? 3 : strength >= 50 ? 2 : strength >= 25 ? 1 : 0
    property color activeColor: Theme.fg
    property color inactiveColor: Theme.fgDim
    Accessible.role: Accessible.StaticText
    Accessible.name: "Wi-Fi" + (strength >= 0 ? " · " + strength + "%" : "")

    onStrengthChanged: requestPaint()
    onActiveColorChanged: requestPaint()
    onInactiveColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 18, height / 18);
        ctx.lineWidth = 1.65;
        ctx.lineCap = "round";
        // Three independently colored waves, from the dot outward.
        for (let wave = 1; wave <= 3; ++wave) {
            ctx.beginPath();
            ctx.strokeStyle = wave <= root.level ? root.activeColor : root.inactiveColor;
            ctx.arc(9, 15, 2 + wave * 3, -3 * Math.PI / 4, -Math.PI / 4);
            ctx.stroke();
        }
        ctx.beginPath();
        ctx.fillStyle = root.strength >= 0 ? root.activeColor : root.inactiveColor;
        ctx.arc(9, 15, 1.2, 0, 2 * Math.PI);
        ctx.fill();
    }
}
