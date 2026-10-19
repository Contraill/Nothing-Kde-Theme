// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's system designs (Prince-1652, MIT): the status block
// (battery, RAM pie, disk bar), CPU as a block with a bar or a pill with a
// pie, and network speeds as a block or a pill.
Glassy.EveryFrame {
    id: f
    // "status", "cpu", "cpu-pill", "network" or "network-pill"
    property string layout: "status"
    property string family
    property real cpu: 0
    property real memory: 0
    property real diskUsed: 0
    property real diskTotal: 0
    property int battery: -1
    property bool charging: false
    property string download: "0 B"
    property string upload: "0 B"
    readonly property bool pill: layout.endsWith("pill")
    designWidth: layout === "status" ? 390 : 190
    designHeight: pill ? 95 : 190
    card: pill ? "pill" : "block"

    component Label: Glassy.EveryText {
        s: f.s
        color: f.colors.textPrimary
        font.family: f.family
    }

    // Status: battery on the left, RAM and disk on the right.
    Label { visible: f.layout === "status"; px: 16; py: 20; pt: 32; value: (f.battery >= 0 ? f.battery : 0) + "%" }
    Label {
        visible: f.layout === "status"; px: 20; py: 68; pt: 13; upper: true
        value: f.battery < 0 ? i18n("No battery") : f.charging ? i18n("Charging") : i18n("Discharging")
    }
    Glassy.EveryBar {
        visible: f.layout === "status"
        s: f.s; bx: 20; by: 105; bw: 165; bh: 65; radius: 15
        value: Math.max(0, f.battery) / 100
        trackColor: f.track
        fillColor: f.colors.accent
        Glassy.DotGlyph {
            name: "bolt-dots"
            visible: f.charging
            anchors.centerIn: parent
            width: 7 * 4 * f.s
            height: 9 * 4 * f.s
            dotRatio: 0.75
            color: f.colors.textPrimary
        }
    }
    Glassy.EveryPie {
        visible: f.layout === "status"
        s: f.s; cx: 237.5; cy: 52.5; radius: 32.5
        value: f.memory / 100
        trackColor: f.track
        fillColor: f.colors.accent
    }
    Label { visible: f.layout === "status"; px: 285; py: 25; pt: 24; value: Math.round(f.memory) + "%" }
    Label { visible: f.layout === "status"; px: 285; py: 64; pt: 16; value: "RAM" }
    Glassy.EveryBar {
        visible: f.layout === "status"
        s: f.s; bx: 205; by: 105; bw: 165; bh: 65; radius: 15
        value: f.diskTotal > 0 ? f.diskUsed / f.diskTotal : 0
        trackColor: f.track
        fillColor: f.colors.accent
        Label {
            px: 82; py: 35; pt: 12; align: "CenterCenter"
            value: Math.round(f.diskUsed / 1073741824) + "GB / " + Math.round(f.diskTotal / 1073741824) + "GB"
        }
    }

    // CPU block
    Label { visible: f.layout === "cpu"; px: 95; py: 20; pt: 32; align: "Center"; value: Math.round(f.cpu) + "%" }
    Label { visible: f.layout === "cpu"; px: 95; py: 68; pt: 13; align: "Center"; value: "CPU" }
    Glassy.EveryBar {
        visible: f.layout === "cpu"
        s: f.s; bx: 20; by: 105; bw: 150; bh: 65; radius: 15
        value: f.cpu / 100
        trackColor: f.track
        fillColor: f.colors.accent
    }
    // CPU pill
    Glassy.EveryPie {
        visible: f.layout === "cpu-pill"
        s: f.s; cx: 47.5; cy: 47.5; radius: 32.5
        value: f.cpu / 100
        trackColor: f.track
        fillColor: f.colors.accent
    }
    Label { visible: f.layout === "cpu-pill"; px: 95; py: 52; pt: 24; align: "LeftBottom"; value: Math.round(f.cpu) + "%" }
    Label { visible: f.layout === "cpu-pill"; px: 95; py: 57; pt: 16; align: "LeftTop"; value: "CPU" }

    // Network block
    Label { visible: f.layout === "network"; px: 95; py: 20; pt: 24; align: "Center"; upper: true; value: i18n("Network") }
    Label { visible: f.layout === "network"; px: 95; py: 75; pt: 16; align: "Center"; value: "DL: " + f.download }
    Label { visible: f.layout === "network"; px: 95; py: 115; pt: 16; align: "Center"; value: "UL: " + f.upload }
    Rectangle {
        visible: f.layout === "network"
        x: 87 * f.s; y: 152 * f.s; width: 16 * f.s; height: width; radius: width / 2
        color: f.colors.accent
    }
    // Network pill
    Label { visible: f.layout === "network-pill"; px: 47.5; py: 52; pt: 20; align: "CenterCenter"; value: "NET"; color: f.colors.accent }
    Label { visible: f.layout === "network-pill"; px: 90; py: 45; pt: 12; align: "LeftBottom"; value: "D: " + f.download }
    Label { visible: f.layout === "network-pill"; px: 90; py: 55; pt: 12; align: "LeftTop"; value: "U: " + f.upload }
}
