pragma Singleton
import QtQuick

QtObject {
    readonly property var stats: Backend.stats
    readonly property int cpu: stats?.cpuPercent ?? 0
    readonly property int cpuTemp: stats?.temperature ?? -1
    readonly property int mem: stats?.memoryPercent ?? 0
    readonly property string memText: mem + "%"
    readonly property string memShort: memText
    readonly property int gpu: stats?.gpuPercent ?? -1
    readonly property int gpuTemp: stats?.gpuTemperature ?? -1
    readonly property bool gpuAvailable: stats?.gpuAvailable ?? false
    // A suspended discrete GPU is left asleep and reported as such.
    readonly property bool gpuAsleep: stats?.gpuAsleep ?? false
}
