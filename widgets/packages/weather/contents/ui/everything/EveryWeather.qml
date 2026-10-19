// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import "../../../../../shared" as Glassy

// EveryThing-UI's weather (Prince-1652, MIT): the temperature, the
// condition in the accent and an outlined accent icon.
Glassy.EveryFrame {
    id: f
    property string family
    property string temperature: "--"
    property string condition: ""
    // Open-Meteo / WMO weather code.
    property int code: -1
    designWidth: 190
    designHeight: 190
    card: "block"
    // 0 clear, 1 cloudy, 2 rain, 3 snow, 4 storm (as the original groups them).
    readonly property int state: code <= 1 ? 0 : code <= 48 ? 1 : (code >= 51 && code <= 67) || (code >= 80 && code <= 82) ? 2
        : (code >= 71 && code <= 77) || code === 85 || code === 86 ? 3 : code >= 95 ? 4 : 1

    Glassy.EveryText {
        s: f.s; px: 15; py: 88; pt: 36
        value: f.temperature + "°"
        color: f.colors.textPrimary
        font.family: f.family
    }
    Glassy.EveryText {
        s: f.s; px: 15; py: 140; pt: 18; clipWidth: 160; upper: true
        value: f.condition
        color: f.colors.accent
        font.family: f.family
    }
    // The icons, drawn as in the original on a 50 px box at (130, 13).
    Shape {
        id: icon
        x: 130 * f.s
        y: 13 * f.s
        width: 60 * f.s
        height: 60 * f.s
        preferredRendererType: Shape.CurveRenderer
        // A cloud flat along y 40: left, top and right bumps.
        readonly property string cloud: "M14 40A9 9 0 0 1 14 22A13 13 0 0 1 39 21A9.5 9.5 0 0 1 40 40Z"
        ShapePath {
            strokeWidth: 4
            strokeColor: f.colors.accent
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            scale: Qt.size(f.s, f.s)
            PathSvg {
                path: f.state === 0
                    ? "M37 25A12 12 0 1 1 13 25A12 12 0 1 1 37 25 M25 5V8 M25 42V45 M5 25H8 M42 25H45"
                    : f.state === 2 ? icon.cloud + " M15 48L10 55 M27 48L22 55 M39 48L34 55"
                    : f.state === 4 ? icon.cloud + " M28 44L22 52H30L24 60"
                    : icon.cloud
            }
        }
        ShapePath {
            strokeWidth: -1
            fillColor: f.state === 3 ? f.colors.accent : "transparent"
            scale: Qt.size(f.s, f.s)
            PathSvg { path: "M12 50A3 3 0 1 1 18 50A3 3 0 1 1 12 50 M24 50A3 3 0 1 1 30 50A3 3 0 1 1 24 50 M36 50A3 3 0 1 1 42 50A3 3 0 1 1 36 50" }
        }
    }
}
