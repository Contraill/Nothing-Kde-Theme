import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island

Item {
    width: 400
    height: 120
    QtObject {
        id: backend
        property bool brightnessAvailable: true
        property int brightness: 50
        property bool keyboardBrightnessAvailable: false
        property int keyboardBrightness: 67
        property int keyboardBrightnessMax: 3
        property int keyboardWrite: -1
        property int displayWrite: -1
        function setKeyboardBrightness(value) { keyboardWrite = value; }
        function setDisplayBrightness(value) { displayWrite = value; }
    }
    Island.BrightnessCard { id: card; width: 300; height: 52 }
    SignalSpy { id: opened; target: card; signalName: "requestDetails" }
    SignalSpy { id: moved; signalName: "moved" }
    TestCase {
        name: "KeyboardBrightness"
        when: windowShown
        function init() {
            Island.Backend.preview = true;
            Island.Backend.controls = backend;
            backend.keyboardBrightnessAvailable = false;
            backend.keyboardWrite = -1;
            backend.displayWrite = -1;
            card.keyboardMode = false;
            card.pendingValue = -1;
            opened.clear();
            moved.target = findChild(card, "brightnessSlider");
            moved.clear();
        }
        function cleanup() { card.flush(); Island.Backend.preview = true; }
        function test_unsupported_right_click_does_not_open() {
            mouseClick(card, 30, 15, Qt.RightButton);
            compare(opened.count, 0);
        }
        function test_supported_right_click_opens_over_slider() {
            backend.keyboardBrightnessAvailable = true;
            const slider = findChild(card, "brightnessSlider");
            mouseClick(slider, slider.width / 2, slider.height / 2, Qt.RightButton);
            compare(opened.count, 1);
        }
        function test_right_click_layer_keeps_display_drag_working() {
            backend.keyboardBrightnessAvailable = true;
            const slider = findChild(card, "brightnessSlider");
            mouseClick(slider, slider.width * 0.8, slider.height / 2, Qt.LeftButton);
            verify(moved.count > 0);
            compare(opened.count, 0);
        }
        function test_keyboard_off_routes_only_to_keyboard_backend() {
            backend.keyboardBrightnessAvailable = true;
            card.keyboardMode = true;
            Island.Backend.preview = false;
            card.pendingValue = 0;
            card.flush();
            compare(backend.keyboardWrite, 0);
            compare(backend.displayWrite, -1);
            compare(findChild(card, "brightnessSlider").from, 0);
        }
        function test_unavailable_keyboard_cannot_write() {
            card.keyboardMode = true;
            Island.Backend.preview = false;
            card.pendingValue = 100;
            card.flush();
            compare(backend.keyboardWrite, -1);
        }
    }
}
