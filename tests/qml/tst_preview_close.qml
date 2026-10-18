import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island
import "../../plasmoids/com.nothingplasma.panel/contents/ui/components" as Components
Item {
    width: 760
    height: 260
    QtObject {
        id: tasks
        property var closed: []
        signal dataChanged()
        function makeModelIndex(row, child) { return {row: child === undefined ? row : child}; }
        function data(index, role) { return role === 0 ? "Window " + index.row : null; }
        function requestClose(index) { closed = closed.concat([index.row]); }
        function requestActivate(index) {}
    }
    QtObject { id: info; property var desktopIds: []; property var desktopNames: []; property var currentDesktop: "" }
    Components.TaskPreviewContent {
        id: preview
        anchors.fill: parent
        tasksModel: tasks
        desktopInfo: info
        rootRow: 0
        grouped: true
        childCount: 2
        appName: "Test"
        fallbackIcon: "application-x-executable"
    }
    SignalSpy { id: activated; target: preview; signalName: "windowActivated" }
    TestCase {
        name: "PreviewClose"
        when: windowShown
        function init() { Island.Backend.preview = true; tasks.closed = []; activated.clear(); }
        function card(row) {
            const found = [];
            const walk = item => { for (const child of item.children) { if (child.title === "Window " + row) found.push(child); walk(child); } };
            walk(preview);
            return found[0];
        }
        function test_middle_click_closes_only_that_window() {
            preview.grouped = true;
            preview.childCount = 2;
            tryVerify(() => card(1) !== undefined);
            const second = card(1);
            mouseClick(second, second.width / 2, second.height / 3, Qt.MiddleButton);
            compare(tasks.closed, [1]);
            // Another window of the application remains, so the preview stays.
            compare(activated.count, 0);
        }
        function test_closing_the_last_window_dismisses_the_preview() {
            preview.grouped = false;
            preview.childCount = 1;
            const only = card(0);
            mouseClick(only, only.width / 2, only.height / 3, Qt.MiddleButton);
            compare(tasks.closed, [0]);
            compare(activated.count, 1);
        }
    }
}
