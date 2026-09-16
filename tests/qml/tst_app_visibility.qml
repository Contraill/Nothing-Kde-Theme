import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/ui/components" as Components
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island
Item {
    width: 620; height: 560
    ListModel {
        id: apps
        property int activated: -1
        function trigger(row, action, argument) { activated = row; }
        ListElement { display: "Files"; favoriteId: "files.desktop"; decoration: "system-file-manager" }
        ListElement { display: "Terminal"; favoriteId: "applications:terminal.desktop"; decoration: "utilities-terminal" }
        ListElement { display: "Settings"; favoriteId: "settings.desktop"; decoration: "preferences-system" }
    }
    QtObject { id: config; property var hiddenApplications: [] }
    Components.AppFilter { id: filtered; inputModel: apps; hiddenApps: config.hiddenApplications }
    Component { id: factory; Components.LauncherSettingsPage { width: 620; height: 560; shortcutController: null; appsModel: apps; panelConfig: config } }
    TestCase {
        name: "AppVisibility"
        when: windowShown
        property var page
        function init() { Island.Backend.preview = true; config.hiddenApplications = []; filtered.query = ""; page = factory.createObject(parent); }
        function cleanup() { page.destroy(); }
        function test_hide_restore_and_reload() {
            const list = findChild(page, "applicationVisibilityList");
            tryCompare(list, "count", 3);
            tryVerify(() => list.itemAtIndex(1) !== null);
            mouseClick(list.itemAtIndex(1));
            compare(config.hiddenApplications.length, 1);
            compare(config.hiddenApplications[0], "terminal.desktop");
            tryVerify(() => filtered.rowCount() === 2);
            filtered.trigger(1, "", null); compare(apps.activated, 2);
            // Settings must continue to show hidden apps so users can restore them.
            compare(list.count, 3);
            page.destroy(); page = factory.createObject(parent);
            compare(page.hiddenApps[0], "terminal.desktop");
            page.setAppVisible("terminal.desktop", true);
            tryVerify(() => filtered.rowCount() === 3);
        }
        function test_search_cannot_bypass_hidden_apps() {
            config.hiddenApplications = ["terminal.desktop"];
            filtered.query = "term";
            tryVerify(() => filtered.rowCount() === 0);
            config.hiddenApplications = [];
            tryVerify(() => filtered.rowCount() === 1);
            filtered.trigger(0, "", null); compare(apps.activated, 1);
        }
        function test_model_changes_are_live() {
            config.hiddenApplications = ["terminal.desktop"];
            apps.append({display:"New app", favoriteId:"new.desktop", decoration:"application-x-executable"});
            tryVerify(() => filtered.rowCount() === 3);
            apps.remove(3);
            tryVerify(() => filtered.rowCount() === 2);
        }
    }
}
