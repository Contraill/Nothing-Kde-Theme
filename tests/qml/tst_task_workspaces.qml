import QtQuick
import QtTest
import org.kde.taskmanager as TaskManager
import "../../plasmoids/com.nothingplasma.panel/contents/ui/components" as Components
Item {
    QtObject {
        id: info
        property var desktopIds: ["a", "b", "c"]
        property var desktopNames: ["Main", "Work", "Chat"]
        property var currentDesktop: "a"
    }
    QtObject {
        id: tasks
        property var windows: []
        signal dataChanged()
        function makeModelIndex(row, child) { return {row: child === undefined ? row : child}; }
        function data(index, role) {
            const w = windows[index.row];
            if (!w) return null;
            if (role === TaskManager.AbstractTasksModel.IsWindow) return w.window;
            if (role === TaskManager.AbstractTasksModel.IsOnAllVirtualDesktops) return w.all;
            if (role === TaskManager.AbstractTasksModel.VirtualDesktops) return w.desktops;
            return null;
        }
    }
    Components.TaskWorkspaces { id: state; tasksModel: tasks; desktopInfo: info; row: 0 }
    TestCase {
        name: "TaskWorkspaces"
        function init() { info.currentDesktop="a"; info.desktopNames=["Main","Work","Chat"]; state.grouped=false; state.childCount=1; state.child=-1; }
        function setWindows(windows) { tasks.windows=windows; tasks.dataChanged(); }
        function test_other_current_all_and_launcher() {
            setWindows([{window:true,all:false,desktops:["b"]}]);
            compare(state.otherNames,["Work"]);
            info.currentDesktop="b"; compare(state.otherNames,[]);
            setWindows([{window:true,all:true,desktops:[]}]); compare(state.otherNames,[]);
            setWindows([{window:false,all:false,desktops:["c"]}]); compare(state.otherNames,[]);
        }
        function test_group_reports_other_members_and_updates() {
            state.grouped=true; state.childCount=3;
            setWindows([{window:true,desktops:["a"]},{window:true,desktops:["b","c"]},{window:true,desktops:["b"]}]);
            compare(state.otherNames,["Work","Chat"]);
            info.desktopNames=["Main","Development","Chat"];
            compare(state.otherNames,["Development","Chat"]);
            info.currentDesktop="b"; compare(state.otherNames,["Main","Chat"]);
        }
        function test_single_group_member() {
            state.grouped=true; state.childCount=3;
            setWindows([{window:true,desktops:["a"]},{window:true,desktops:["b","c"]},{window:true,desktops:["c"]}]);
            state.child=0; compare(state.otherNames,[]);
            state.child=1; compare(state.otherNames,["Work","Chat"]);
            state.child=2; compare(state.otherNames,["Chat"]);
        }
    }
}
