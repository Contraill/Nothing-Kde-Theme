import QtQuick

QtObject {
    id: root
    property bool busy: false
    property var request: null
    property int generation: 0
    property var failure: null
    property var createRequest: () => new XMLHttpRequest()
    function cancel() {
        ++generation;
        deadline.stop();
        const old = request;
        request = null; busy = false; failure = null;
        if (old) old.abort();
    }
    function get(url, success, failed) {
        cancel();
        const token = generation;
        const xhr = createRequest();
        request = xhr; busy = true; failure = failed;
        xhr.onreadystatechange = function() {
            if (token !== generation || xhr.readyState !== XMLHttpRequest.DONE) return;
            deadline.stop(); request = null; busy = false; failure = null;
            let data;
            try {
                if (xhr.status !== 200) throw new Error("http");
                data = JSON.parse(xhr.responseText);
            } catch (e) { failed(); return; }
            success(data);
        };
        try { xhr.open("GET", url); deadline.restart(); xhr.send(); }
        catch (e) { cancel(); failed(); }
    }
    readonly property Timer deadline: Timer {
        interval: 12000
        onTriggered: {
            const callback = root.failure;
            root.cancel();
            if (callback) callback();
        }
    }
    Component.onDestruction: cancel()
}
