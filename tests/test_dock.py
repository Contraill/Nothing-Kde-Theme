import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / 'plasmoids/com.nothingplasma.panel/contents/ui'


class DockTests(unittest.TestCase):
    def test_requested_hover_labels_are_absent_but_accessibility_is_kept(self):
        bottom = (UI / 'BottomPanel.qml').read_text()
        battery = (UI.parent / 'island/ui/Battery.qml').read_text()
        for text in (bottom, battery):
            self.assertNotIn('ToolTip.', text)
            self.assertIn('Accessible.name:', text)

    def test_expanded_clock_keeps_seconds_next_to_narrow_digits(self):
        text = (UI.parent / 'island/ui/ExpandedPanel.qml').read_text()
        clock = text.split('id: horaTxt', 1)[1].split('TextMetrics', 1)[0]
        self.assertIn('width: moldeHora.width', clock)
        self.assertIn('horizontalAlignment: Text.AlignRight', clock)

    def test_dock_keeps_native_pinning_and_tree_grouping(self):
        text = (UI / 'BottomPanel.qml').read_text()
        for token in ('TaskManager.TasksModel.GroupApplications', 'groupInline: false',
                      'separateLaunchers: true', 'taskReorderingEnabled: true',
                      'Plasmoid.configuration.pinnedLaunchers = taskSourceModel.launcherList',
                      'filterByVirtualDesktop: Plasmoid.configuration.dockCurrentDesktopOnly',
                      'filterByScreen: Plasmoid.configuration.dockCurrentScreenOnly',
                      'KWindowSystem.showingDesktop'):
            self.assertIn(token, text)
        # Windows from every desktop and screen stay visible unless the user opts in.
        schema = (UI.parent / 'config/main.xml').read_text()
        for key in ('dockCurrentDesktopOnly', 'dockCurrentScreenOnly'):
            self.assertIn(f'<entry name="{key}" type="Bool"><default>false</default></entry>', schema)

    def test_meta_number_shortcuts_reach_the_dock(self):
        text = (UI / 'BottomPanel.qml').read_text()
        # Same actions as Plasma's task manager, registered once (primary screen).
        self.assertIn('"activate task manager entry " + n', text)
        self.assertIn('member: "doRegister", signature: "(as)"', text)
        self.assertIn('member: "setShortcut", signature: "(asaiu)"', text)
        self.assertIn('readonly property bool ownsEntryShortcuts: Plasmoid.containment.screen === 0', text)
        self.assertIn('taskStrip.activateEntry(Number(match[1]) - 1)', text)

    def test_icons_publish_geometry_and_accept_files(self):
        text = (UI / 'components/TaskStrip.qml').read_text()
        for token in ('requestPublishDelegateGeometry(task.modelIndex', 'requestOpenUrls(task.modelIndex, files)',
                      'root.cycleTask(task.index, direction)', 'Island.Notifs.jobsByApp[appId]',
                      'Island.Notifs.unreadByApp[appId]'):
            self.assertIn(token, text)

    def test_group_click_and_reorder_are_not_hover_only(self):
        text = (UI / 'components/TaskStrip.qml').read_text()
        for token in ('root.chooseWindows(index, windowCount', 'tasksModel.move(from, to)',
                      'tasksModel.syncLaunchers()', 'requestNewInstance', 'requestToggleMinimized',
                      'onRowsAboutToBeRemoved', 'onRowsAboutToBeInserted', 'CLOSE ALL WINDOWS'):
            self.assertIn(token, text)
        self.assertIn('clip: true', text)

    def test_wayland_preview_is_visible_only_and_uses_uuid(self):
        text = (UI / 'components/TaskPreviewContent.qml').read_text()
        self.assertIn('root.Window.window?.visible', text)
        self.assertIn('!Island.Backend.preview', text)
        native = (UI / 'components/NativeWindowThumbnail.qml').read_text()
        self.assertIn('ScreencastingRequest', native)
        self.assertIn('uuid: String(root.windowId)', native)
        # Plasma 6 has no PlasmaCore.WindowThumbnail; naming it broke the whole file.
        self.assertNotIn('PlasmaCore.WindowThumbnail {', native)
        self.assertIn('active: root.waylandId', native)

    def test_all_dock_strings_have_tr_en_translations(self):
        source = (UI.parent / 'island/ui/Translations.js').read_text()
        catalogs = json.loads(source.split('var catalogs = ', 1)[1].rstrip().rstrip(';'))
        for name in ('BottomPanel.qml', 'components/TaskStrip.qml', 'components/TaskPreviewContent.qml',
                     'components/LauncherPage.qml', 'components/LauncherSettingsPage.qml'):
            for key in re.findall(r'Island\.Cfg\.t\("([^"]+)"\)', (UI / name).read_text()):
                self.assertIn(key, catalogs['en'], name)
                self.assertIn(key, catalogs['tr'], name)
