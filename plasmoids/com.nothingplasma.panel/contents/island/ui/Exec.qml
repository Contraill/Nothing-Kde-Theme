pragma Singleton
import QtQuick
import "../../ui/components" as Components

QtObject {
    id: root
    readonly property Components.Exec runner: Components.Exec {}
    function quote(value) { return "'" + String(value).replace(/'/g, "'\\''") + "'"; }
    function command(cmd) { return "sh -c " + quote(cmd); }
    function run(cmd, callback) {
        if (!Backend.preview) runner.run(command(cmd), callback);
    }
}
