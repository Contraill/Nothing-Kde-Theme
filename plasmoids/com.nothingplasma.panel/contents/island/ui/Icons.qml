pragma Singleton

import QtQuick
QtObject {
    readonly property string cpu: "speed"
    readonly property string mem: "memory"

    readonly property string volHigh: "volume_up"
    readonly property string volLow: "volume_down"
    readonly property string volMute: "volume_off"

    readonly property string wifi: "wifi"
    readonly property string wifiOff: "wifi_off"
    readonly property string ethernet: "lan"

    readonly property string batFull: "battery_full"
    readonly property string bat3q: "battery_6_bar"
    readonly property string batHalf: "battery_4_bar"
    readonly property string batQuarter: "battery_2_bar"
    readonly property string batEmpty: "battery_alert"
    readonly property string batCharging: "battery_charging_full"

    readonly property string play: "play_arrow"
    readonly property string pause: "pause"
    readonly property string next: "skip_next"
    readonly property string prev: "skip_previous"
    readonly property string music: "music_note"

    readonly property string close: "close"
    readonly property string bell: "notifications"
    readonly property string clearAll: "delete_sweep"
}
