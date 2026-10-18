pragma Singleton
import QtQuick
import "../../ui/components" as Components
import "../../ui/components/RuntimePaths.js" as RuntimePaths

QtObject {
    id: root
    property var profiles: []
    property string profile: ""
    property bool cameraAvailable: false
    property bool cameraBlocked: false
    property bool cameraMixed: false
    // privacy-system.sh lets the camera be turned off without a password.
    property bool cameraPasswordless: false
    property bool microphoneAvailable: false
    property bool microphoneBlocked: false
    property bool microphonePartial: false
    property bool busy: false
    property bool refreshing: false
    property string errorKey: ""
    readonly property string error: errorKey ? Cfg.t(errorKey) : ""
    readonly property Components.Exec runner: Components.Exec {}

    function helper(args, privileged) {
        return RuntimePaths.command(Qt.resolvedUrl("../../tools/privacy.py"), "privacy.py",
            privileged ? "pkexec /usr/bin/python3 -I" : "python3", args);
    }
    function refresh() {
        if (Backend.preview || busy || refreshing) return;
        refreshing = true;
        runner.run(helper("status", false), result => {
            refreshing = false;
            try {
                if (result.exitCode !== 0) throw new Error("status");
                const state = JSON.parse(result.stdout);
                profiles = state.profiles || [];
                profile = state.profile || "";
                cameraAvailable = state.cameraAvailable === true;
                cameraBlocked = state.cameraBlocked === true;
                cameraMixed = state.cameraMixed === true;
                cameraPasswordless = state.cameraPasswordless === true;
                microphoneAvailable = state.microphoneAvailable === true;
                microphoneBlocked = state.microphoneBlocked === true;
                microphonePartial = state.microphonePartial === true;
            } catch (e) {
                cameraAvailable = false;
                cameraBlocked = false;
                cameraMixed = false;
                microphoneAvailable = false;
                microphoneBlocked = false;
                microphonePartial = false;
                profiles = [];
            }
        });
    }
    function finish(result) {
        busy = false;
        errorKey = "";
        if (result.exitCode !== 0) {
            errorKey = result.exitCode === 126 || result.exitCode === 127 ? "AUTH CANCELLED" : "ACTION FAILED";
            try { if (JSON.parse(result.stdout).error === "capture-busy") errorKey = "MIC BUSY"; } catch (e) {}
        }
        refresh();
    }
    function setProfile(value) {
        if (Backend.preview || busy || !profiles.includes(value)) return;
        busy = true;
        runner.run("powerprofilesctl set " + RuntimePaths.quote(value), result => root.finish(result));
    }
    function toggleCamera() {
        if (Backend.preview || busy || !cameraAvailable) return;
        busy = true;
        const command = !cameraBlocked && cameraPasswordless ? "pkexec /usr/local/libexec/nothing-kde-privacy camera off"
            : helper("camera " + (cameraBlocked ? "on" : "off"), true);
        runner.run(command, result => root.finish(result));
    }
    function toggleMicrophone() {
        if (Backend.preview || busy || (!microphoneAvailable && !microphonePartial)) return;
        busy = true;
        runner.run(helper("microphone " + (microphoneBlocked || microphonePartial ? "on" : "off"), true), result => root.finish(result));
    }
    readonly property Timer clearError: Timer {
        interval: 12000
        running: Backend.expanded && root.errorKey.length > 0
        onTriggered: root.errorKey = ""
    }
    readonly property Timer poll: Timer {
        interval: 4000
        running: Backend.expanded && !Backend.preview
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
