pragma ComponentBehavior: Bound

import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "RuntimePaths.js" as RuntimePaths

// KDE's system monitor service (ksystemstats); sensors are subscribed only while
// the island is open, so nothing is sampled in the background.
Item {
    id: root

    property bool active: true
    readonly property int cpuPercent: root.ready(cpuUsage) ? Math.round(cpuUsage.value) : 0
    readonly property int memoryPercent: root.ready(memoryUsed) ? Math.round(memoryUsed.value) : 0
    readonly property int temperature: root.ready(cpuTemperature) && cpuTemperature.value > 0 ? Math.round(cpuTemperature.value) : -1

    // The discrete GPU when there is one, otherwise the only GPU.
    property string gpuId: ""
    property bool gpuAsleep: false
    readonly property bool gpuAvailable: gpuId !== ""
    readonly property int gpuPercent: gpuAvailable && !gpuAsleep && root.ready(gpuUsage) ? Math.round(gpuUsage.value) : -1
    readonly property int gpuTemperature: gpuAvailable && !gpuAsleep && root.ready(gpuTemp) && gpuTemp.value > 0 ? Math.round(gpuTemp.value) : -1
    // Vendor of the discrete GPU from sysfs, used to find its ksystemstats id.
    property string discreteVendor: ""

    function ready(sensor): bool {
        return sensor.status === Sensors.Sensor.Ready && Number.isFinite(Number(sensor.value));
    }

    Sensors.Sensor { id: cpuUsage; sensorId: "cpu/all/usage"; enabled: root.active }
    Sensors.Sensor { id: memoryUsed; sensorId: "memory/physical/usedPercent"; enabled: root.active }
    Sensors.Sensor { id: cpuTemperature; sensorId: "cpu/all/averageTemperature"; enabled: root.active }
    // Sampling a suspended NVIDIA/AMD GPU would wake it; subscribe only while it is awake.
    Sensors.Sensor { id: gpuUsage; sensorId: root.gpuId ? root.gpuId + "/usage" : ""; enabled: root.active && root.gpuAvailable && !root.gpuAsleep }
    Sensors.Sensor { id: gpuTemp; sensorId: root.gpuId ? root.gpuId + "/temperature" : ""; enabled: gpuUsage.enabled }

    // GPU names are static metadata and do not start the vendor sampler.
    Instantiator {
        id: gpuNames
        model: 4
        delegate: Sensors.Sensor {
            required property int index
            sensorId: "gpu/gpu" + index + "/name"
            enabled: root.active
            onValueChanged: root.pickGpu()
            onStatusChanged: root.pickGpu()
        }
    }
    function pickGpu(): void {
        const patterns = {"0x10de": /nvidia|geforce|quadro|rtx|gtx/i, "0x1002": /amd|radeon/i, "0x8086": /intel|arc/i};
        let first = "";
        for (let i = 0; i < gpuNames.count; ++i) {
            const sensor = gpuNames.objectAt(i);
            const name = sensor ? String(sensor.value ?? "") : "";
            if (!sensor || sensor.status !== Sensors.Sensor.Ready || !name) continue;
            const id = "gpu/gpu" + i;
            if (!first) first = id;
            if (root.discreteVendor && patterns[root.discreteVendor]?.test(name)) {
                root.gpuId = id;
                return;
            }
        }
        root.gpuId = root.discreteVendor ? "" : first;
    }

    Exec { id: exec }
    function refreshGpuPower(): void {
        exec.run(RuntimePaths.command(Qt.resolvedUrl("../../tools/nothing-control.sh"), "nothing-control.sh", "bash", "gpu-power"), function(result) {
            if (result.exitCode !== 0) return;
            const discrete = result.stdout.split("\n").map(line => line.trim().split(" ")).find(f => f.length === 3 && f[1] === "0");
            root.discreteVendor = discrete ? discrete[0] : "";
            root.gpuAsleep = discrete ? discrete[2] === "suspended" : false;
            root.pickGpu();
        });
    }
    Timer {
        interval: 5000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refreshGpuPower()
    }
}
