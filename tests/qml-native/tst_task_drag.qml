import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/ui/components" as Components
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island
Item {
    width: 400; height: 100
    ListModel {
        id: tasks
        property var launcherList: []
        property int saves: 0
        function launcherPosition(url) { return launcherList.indexOf(String(url)); }
        function makeModelIndex(row) { return index(row, 0); }
        function syncLaunchers() {
            ++saves;
            let next = [];
            for (let i=0; i<count; ++i) next.push(get(i).LauncherUrl);
            launcherList = next;
        }
        function move(from, to) {
            const entry = JSON.parse(JSON.stringify(get(from)));
            remove(from); insert(to, entry);
            return true;
        }
    }
    Components.TaskStrip { id: strip; width: 132; height: 38; tasksModel: tasks }
    TestCase {
        name: "TaskDrag"
        when: windowShown
        property var original: ["applications:org.kde.dolphin.desktop", "applications:org.kde.kate.desktop", "applications:steam.desktop"]
        function init() {
            Island.Backend.preview = true;
            tasks.clear();
            for (const url of original) tasks.append({LauncherUrl:url, AppName:url, decoration:"application-x-executable", IsLauncher:true});
            tasks.launcherList = original; tasks.saves = 0;
            tryCompare(findChild(strip, "dockTaskList"), "count", 3);
            tryVerify(() => findChild(strip, "dockTaskPointer-0") !== null);
            waitForRendering(strip, 100);

        }
        function cleanup() { strip.finishDrag(false); }
        function test_drag_previews_then_commits_once() {
            mousePress(strip, 18, 18, Qt.LeftButton);
            mouseMove(strip, 70, 18, 30, Qt.LeftButton);
            tryCompare(strip, "dragging", true);
            mouseMove(strip, 114, 18, 30, Qt.LeftButton);
            compare(strip.dropRow, 2);
            compare(tasks.launcherList, original); // nothing persisted while hovering
            mouseRelease(strip, 114, 18, Qt.LeftButton);
            tryCompare(strip, "dragging", false);
            compare(tasks.launcherList, [original[1], original[2], original[0]]);
            compare(tasks.saves, 1);
        }
        function test_drop_outside_cancels_without_changing_order() {
            mousePress(strip, 18, 18, Qt.LeftButton);
            mouseMove(strip, 70, 18, 30, Qt.LeftButton);
            tryCompare(strip, "dragging", true);
            mouseRelease(strip, 70, 95, Qt.LeftButton);
            compare(strip.dragging, false);
            compare(tasks.launcherList, original);
        }
        function test_no_move_does_not_reorder() {
            strip.dragRow = 1; strip.dropRow = 1;
            strip.finishDrag(true);
            compare(tasks.launcherList, original);
        }
    }
}
