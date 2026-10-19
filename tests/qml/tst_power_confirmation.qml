import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island

Item {
    width: 400; height: 600
    QtObject { id: config; property bool confirmPowerActions: true; property string appearanceMode: "dark" }
    Component { id: factory; Island.PowerView { panelConfig: config } }
    Component { id: settingsFactory; Island.AccentSettings { panelConfig: config; width: 400 } }
    SignalSpy { id: spy; signalName: "actionRequested" }
    TestCase {
        name: "PowerConfirmation"
        when: windowShown
        property var page
        function init() {
            Island.Backend.preview=true; config.confirmPowerActions=true;
            page=factory.createObject(parent);spy.target=page;spy.clear();
        }
        function cleanup() { spy.target=null;page.destroy(); }
        function test_actions_data() {
            return ["Shutdown","Restart","Logout","Sleep"].map(a=>({tag:a,action:a}));
        }
        function test_actions(data) {
            page.requestAction(data.action,"test-only",true);
            compare(spy.count,0);compare(page.pending,data.action);
            page.requestAction(data.action,"test-only",true);compare(page.pending,"");
            config.confirmPowerActions=false;
            page.requestAction(data.action,"test-only",true);
            compare(spy.count,1);compare(page.pending,"");
        }
        function test_menu_contains_only_native_session_actions() {
            const commands = [];
            function collect(item) {
                if (item.command !== undefined) commands.push(item.command);
                for (const child of item.children || []) collect(child);
            }
            collect(page);
            compare(commands.length, 6);
            const session = "busctl --user call org.kde.Shutdown /Shutdown org.kde.Shutdown ";
            const power = "busctl --user call org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement ";
            for (const command of [
                session + "logout", session + "logoutAndReboot", session + "logoutAndShutdown",
                power + "Suspend", power + "Hibernate",
                "busctl --user call org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver Lock"
            ]) verify(commands.includes(command), command);
        }
        function test_reload_preserves_false() {
            config.confirmPowerActions=false;spy.target=null;page.destroy();
            page=factory.createObject(parent);spy.target=page;
            compare(page.confirmPowerActions,false);
            page.requestAction("Sleep","test-only",true);compare(spy.count,1);
        }
        function test_confirmation_change_clears_pending() {
            page.requestAction("Shutdown","test-only",true);
            config.confirmPowerActions=false;compare(page.pending,"");compare(spy.count,0);
        }
        function test_settings_toggle_saves_and_reloads() {
            let settings=settingsFactory.createObject(parent);
            let toggle=findChild(settings,"confirmPowerActionsSwitch");
            verify(toggle);compare(toggle.checked,true);
            toggle.toggle();toggle.toggled();compare(config.confirmPowerActions,false);
            settings.destroy();settings=settingsFactory.createObject(parent);
            toggle=findChild(settings,"confirmPowerActionsSwitch");compare(toggle.checked,false);
            settings.destroy();
        }
    }
}
