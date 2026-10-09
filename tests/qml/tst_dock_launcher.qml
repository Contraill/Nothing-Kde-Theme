import QtQuick
import QtQuick.Window
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/ui/components" as Components
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island
Item {
    id: scene
    width: 620; height: 550
    ListModel {
        id: apps
        property int activatedRow: -1
        function trigger(row, action, arg) { activatedRow = row; }
    }
    QtObject {
        id: runner
        property string query: ""
        property int count: 0
        function modelForRow(row) { return null; }
    }
    QtObject {
        id: tasks
        property var launcherList: ["applications:test.desktop"]
        function launcherPosition(url) { return launcherList.indexOf(String(url)); }
    }
    Components.LauncherPage { id: page; anchors.fill: parent; appsModel: apps; runnerModel: runner; tasksModel: tasks }
    SignalSpy { id: launched; target: page; signalName: "launched" }
    SignalSpy { id: localSettings; target: page; signalName: "settingsRequested" }
    SignalSpy { id: systemSettings; target: page; signalName: "systemSettingsRequested" }
    TestCase {
        name: "DockLauncher"
        when: windowShown
        function init() {
            Island.Backend.preview = true;
            page.hiddenApps = [];
            page.active = false;
            page.resetSearch();
            apps.clear();
            apps.append({display:"Files", decoration:"system-file-manager", favoriteId:"test.desktop"});
            apps.append({display:"Terminal", decoration:"utilities-terminal", favoriteId:"terminal.desktop"});
            apps.append({display:"Settings", decoration:"preferences-system", favoriteId:"settings.desktop"});
            apps.activatedRow = -1;
            launched.clear();
            page.active = true;
            scene.Window.window.requestActivate();
            tryCompare(findChild(page, "dockAppGrid"), "count", 3);
            wait(30); // Let the scheduled initial search focus settle first.
        }
        function cleanup() { page.active = false; }
        function test_settings_left_and_right_are_separate() {
            localSettings.clear(); systemSettings.clear();
            const button = findChild(page, "launcherSettingsButton");
            mouseClick(button, button.width / 2, button.height / 2, Qt.RightButton);
            compare(systemSettings.count, 1); compare(localSettings.count, 0);
            mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton);
            compare(systemSettings.count, 1); compare(localSettings.count, 1);
        }
        function test_keyboard_grid_selection_launches_selected_app() {
            const search = findChild(page, "dockSearch");
            tryCompare(search, "activeFocus", true);
            keyClick(Qt.Key_Down);
            const grid = findChild(page, "dockAppGrid");
            tryCompare(grid, "focus", true);
            keyClick(Qt.Key_Right);
            compare(grid.currentIndex, 1);
            keyClick(Qt.Key_Return);
            compare(apps.activatedRow, 1);
            compare(launched.count, 1);
        }
        function test_search_uses_runner_and_does_not_launch_empty_result() {
            findChild(page, "dockSearch").text = "no-such-application";
            compare(runner.query, "no-such-application");
            tryCompare(findChild(page, "dockAppGrid"), "count", 0);
            page.activateFirst();
            compare(launched.count, 0);
        }
        function test_closing_clears_search() {
            findChild(page, "dockSearch").text = "Terminal";
            page.active = false;
            compare(runner.query, "");
            compare(findChild(page, "dockSearch").text, "");
        }
        function test_hidden_apps_are_removed_and_keyboard_maps_source_row() {
            page.hiddenApps = ["utilities-terminal.desktop", "test.desktop"];
            const grid = findChild(page, "dockAppGrid");
            tryCompare(grid, "count", 2);
            grid.currentIndex = 1;
            page.activateFirst();
            compare(apps.activatedRow, 2);
            page.hiddenApps = [];
            tryCompare(grid, "count", 3);
        }
        function test_pin_identity_normalization() {
            compare(page.launcherUrlFor({favoriteId:"test.desktop"}), "applications:test.desktop");
            compare(page.isPinned({favoriteId:"test.desktop"}), true);
            compare(page.isPinned({favoriteId:"other.desktop"}), false);
            compare(page.launcherUrlFor({}), "");
        }
    }
}
