import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island

Item {
    width: 560; height: 600
    QtObject {
        id: controls
        property bool accentBusy: false
        property color activeAccent: "#806ee7"
        property bool accentReady: true
        function refreshAccent() {}
        property string accentError: ""
        property var accentLinks: ({enabled: {starship: false}, available: {starship: true}})
        property bool themeBusy: false
        property string themeError: ""
        property bool linksBusy: false
        property string linksError: ""
        property int linkCalls: 0
        function refreshAccentLinks() {}
        function setAccentLink(target, enabled) {
            linkCalls++;
            const nextEnabled = Object.assign({}, accentLinks.enabled);
            nextEnabled[target] = enabled;
            accentLinks = {enabled: nextEnabled, available: accentLinks.available};
        }
        property int calls: 0
        property color lastColor: "#000000"
        function applyAccent(value) { calls++; lastColor = value; activeAccent = value; }
    }
    Island.AccentSettings { id: page; width: parent.width; controls: controls }
    TestCase {
        name: "AccentSettings"
        when: windowShown
        function init() {
            Island.Backend.preview = false;
            controls.calls = 0;
            page.draftDirty = false;
            controls.accentBusy = false;
            controls.linksBusy = false;
            controls.linkCalls = 0;
            controls.accentLinks = {enabled: {starship: false}, available: {starship: true}};
            findChild(page, "accentColorPicker").setColor("#ab1234");
        }
        function cleanup() { Island.Backend.preview = true; }
        function test_open_cancel_and_reopen_use_persisted_color() {
            controls.activeAccent = "#806ee7";
            page.resetDraft();
            fuzzyCompare(page.candidateColor.r, controls.activeAccent.r, 1/255);
            const picker = findChild(page, "accentColorPicker");
            picker.selectPoint(0, 0);
            verify(page.draftDirty);
            page.cancelDraft();
            compare(controls.calls, 0);
            fuzzyCompare(page.candidateColor.b, controls.activeAccent.b, 1/255);
            page.visible = false; page.visible = true;
            fuzzyCompare(page.candidateColor.r, controls.activeAccent.r, 1/255);
        }
        function test_late_refresh_does_not_erase_user_draft() {
            const picker = findChild(page, "accentColorPicker");
            picker.selectPoint(0, 0);
            const candidate = page.candidateColor;
            controls.activeAccent = "#0486ff";
            compare(page.candidateColor, candidate);
            page.cancelDraft();
            fuzzyCompare(page.candidateColor.b, 1, 1/255);
        }
        function test_mouse_selection_is_visual_and_clamped() {
            const picker = findChild(page, "accentColorPicker");
            const field = findChild(page, "colorSaturationValue");
            mouseClick(field, field.width / 2, field.height / 2);
            fuzzyCompare(picker.saturation, 0.5, 0.02);
            fuzzyCompare(picker.brightness, 0.5, 0.02);
            picker.selectPoint(-100, field.height + 100);
            compare(picker.saturation, 0);
            compare(picker.brightness, 0);
            compare(controls.calls, 0);
        }
        function test_visual_color_uses_backend_only_on_apply() {
            compare(controls.calls, 0);
            mouseClick(findChild(page, "accentApply"));
            compare(controls.calls, 1);
            // HSV/RGB conversion uses different QColor precision; compare RGB channels.
            fuzzyCompare(controls.lastColor.r, 171 / 255, 1 / 255);
            fuzzyCompare(controls.lastColor.g, 18 / 255, 1 / 255);
            fuzzyCompare(controls.lastColor.b, 52 / 255, 1 / 255);
        }
        function test_keyboard_adjusts_color_without_applying() {
            const picker = findChild(page, "accentColorPicker");
            const field = findChild(page, "colorSaturationValue");
            picker.saturation = 0.5;
            picker.brightness = 0.5;
            field.forceActiveFocus();
            keyClick(Qt.Key_Right);
            keyClick(Qt.Key_Up);
            fuzzyCompare(picker.saturation, 0.52, 0.001);
            fuzzyCompare(picker.brightness, 0.52, 0.001);
            const hue = findChild(page, "colorHue");
            hue.forceActiveFocus();
            const previous = picker.hue;
            keyClick(Qt.Key_Left);
            verify(picker.hue < previous);
            compare(controls.calls, 0);
        }
        function test_busy_rejects_duplicate_request() {
            controls.accentBusy = true;
            page.choose("#D71921");
            compare(controls.calls, 0);
        }
        function test_preview_never_changes_system_accent() {
            Island.Backend.preview = true;
            page.choose("#D71921");
            compare(controls.calls, 0);
        }
        function test_link_toggle_and_disable_restore_route() {
            const button = findChild(page, "accentLink-starship");
            verify(button.visible);
            mouseClick(button);
            compare(controls.linkCalls, 1);
            verify(controls.accentLinks.enabled.starship);
            mouseClick(button);
            compare(controls.linkCalls, 2);
            verify(!controls.accentLinks.enabled.starship);
        }
        function test_preview_does_not_change_external_configs() {
            Island.Backend.preview = true;
            const button = findChild(page, "accentLink-starship");
            verify(!button.enabled);
            compare(controls.linkCalls, 0);
        }
        function test_fastfetch_is_available_when_config_exists() {
            controls.accentLinks = {enabled: {fastfetch: false}, available: {fastfetch: true}};
            const button = findChild(page, "accentLink-fastfetch");
            verify(button.visible);
            mouseClick(button);
            compare(controls.linkCalls, 1);
        }
    }
}
