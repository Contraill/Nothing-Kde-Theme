pragma ComponentBehavior: Bound

import QtQuick
import "RuntimePaths.js" as RuntimePaths

Item {
    id: root

    property bool active: true
    property int cpuPercent: 0
    property int memoryPercent: 0
    property int diskPercent: 0
    property int gpuPercent: -1
    property int temperature: -1
    property int gpuTemperature: -1
    property real downloadKiB: 0
    property real uploadKiB: 0

    property double previousCpuTotal: 0
    property double previousCpuIdle: 0
    property double previousRx: 0
    property double previousTx: 0
    property double previousAt: 0

    Exec { id: exec }

    function helperCommand(): string {
        return RuntimePaths.command(Qt.resolvedUrl("../../tools/nothing-control.sh"), "nothing-control.sh", "bash", "stats")
    }

    function clampPercent(value): int {
        return Math.max(0, Math.min(100, Math.round(value)))
    }

    function refresh(): void {
        exec.run(root.helperCommand(), function(result) {
            if (result.exitCode !== 0 || !result.stdout.length) return
            const p = result.stdout.split("|")
            if (p.length < 9) return

            const total = Number(p[0])
            const idle = Number(p[1])
            if (root.previousCpuTotal > 0 && total > root.previousCpuTotal) {
                const dt = total - root.previousCpuTotal
                const di = idle - root.previousCpuIdle
                root.cpuPercent = root.clampPercent((dt - di) * 100 / dt)
            }
            root.previousCpuTotal = total
            root.previousCpuIdle = idle

            root.memoryPercent = root.clampPercent(Number(p[2]))
            root.diskPercent = root.clampPercent(Number(p[3]))

            const rx = Number(p[4])
            const tx = Number(p[5])
            const now = Date.now()
            if (root.previousAt > 0 && now > root.previousAt) {
                const seconds = (now - root.previousAt) / 1000.0
                root.downloadKiB = Math.max(0, (rx - root.previousRx) / 1024.0 / seconds)
                root.uploadKiB = Math.max(0, (tx - root.previousTx) / 1024.0 / seconds)
            }
            root.previousRx = rx
            root.previousTx = tx
            root.previousAt = now

            root.temperature = Math.round(Number(p[6]))
            root.gpuPercent = Math.round(Number(p[7]))
            root.gpuTemperature = Math.round(Number(p[8]))
        })
    }

    Timer {
        interval: 1200
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
