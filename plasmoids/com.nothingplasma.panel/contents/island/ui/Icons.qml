// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton

import QtQuick

// Material Symbols Rounded ligatures shared by several island parts; other
// icons are named where they are used.
QtObject {
    readonly property string play: "play_arrow"
    readonly property string pause: "pause"
    readonly property string prev: "skip_previous"
    readonly property string next: "skip_next"
    readonly property string music: "music_note"

    readonly property string volHigh: "volume_up"
    readonly property string volLow: "volume_down"
    readonly property string volMute: "volume_off"

    readonly property string wifi: "wifi"
    readonly property string wifiOff: "wifi_off"
    readonly property string ethernet: "lan"

    // Battery levels, full to empty, and charging.
    readonly property string batFull: "battery_full"
    readonly property string bat3q: "battery_6_bar"
    readonly property string batHalf: "battery_4_bar"
    readonly property string batQuarter: "battery_2_bar"
    readonly property string batEmpty: "battery_alert"
    readonly property string batCharging: "battery_charging_full"
}
