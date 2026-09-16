import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: root

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})

        function uniqueCommand(command) {
            let candidate = command
            while (connectedSources.indexOf(candidate) !== -1) {
                candidate += " "
            }
            return candidate
        }

        function run(command, callback) {
            const commandId = uniqueCommand(command)
            if (callback) {
                callbacks[commandId] = callback
            }
            connectSource(commandId)
        }

        onNewData: function(sourceName, data) {
            const callback = callbacks[sourceName]
            const result = {
                stdout: String(data["stdout"] !== undefined ? data["stdout"] : "").trim(),
                stderr: String(data["stderr"] !== undefined ? data["stderr"] : "").trim(),
                exitCode: Number(data["exit code"] !== undefined ? data["exit code"] : -1),
                exitStatus: String(data["exit status"] !== undefined ? data["exit status"] : "")
            }

            disconnectSource(sourceName)
            delete callbacks[sourceName]

            if (callback) {
                callback(result)
            }
        }
    }

    function run(command, callback) {
        executable.run(command, callback)
    }
}
