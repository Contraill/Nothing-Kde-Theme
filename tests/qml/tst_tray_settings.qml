import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island
Item {
    width: 500; height: 1000
    QtObject { id: config; property bool showSystemTray: true; property bool confirmPowerActions: true; property string appearanceMode: "dark" }
    QtObject { id: tray; property int opened: 0; function configure() { ++opened; } }
    Component { id: factory; Island.AccentSettings { width: 450; panelConfig: config; controls: null } }
    TestCase {
        name: "TraySettings"
        when: windowShown
        property var page: null
        function init() {
            Island.Backend.preview = true; Island.Backend.trayHost = tray;
            config.showSystemTray = true; tray.opened = 0; page = factory.createObject(parent);
        }
        function cleanup() { page.destroy(); Island.Backend.trayHost = null; }
        function test_hidden_tray_stays_configurable_and_can_be_restored() {
            const toggle = findChild(page, "showSystemTraySwitch");
            mouseClick(toggle); compare(config.showSystemTray,false);
            page.destroy(); page = factory.createObject(parent);
            compare(findChild(page,"showSystemTraySwitch").checked,false);
            const button = findChild(page,"configureSystemTrayButton");
            compare(button.enabled,true);
            mouseClick(button); compare(tray.opened,1);
            mouseClick(findChild(page,"showSystemTraySwitch"));
            compare(config.showSystemTray,true);
        }
    }
}
