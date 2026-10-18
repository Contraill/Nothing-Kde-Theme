pragma Singleton
import QtQuick
import org.kde.plasma.private.batterymonitor as BatteryMonitor
import "."

// Coffee mode is a PowerDevil inhibition held by plasmashell, so a shell restart
// drops it. The saved panel setting restores it on the next start.
QtObject {
    id: root
    property var panelConfig: null
    readonly property BatteryMonitor.InhibitionControl control: BatteryMonitor.InhibitionControl {}
    readonly property bool active: control.isManuallyInhibited
    property bool restored: false

    function set(enabled) {
        if (Backend.preview) return;
        if (enabled) root.control.inhibit("Nothing KDE · " + Cfg.t("COFFEE MODE"));
        else root.control.uninhibit();
        if (root.panelConfig) root.panelConfig.coffeeMode = enabled;
    }
    function toggle() { root.set(!root.active); }

    // Give the inhibition service a moment to register before re-applying.
    readonly property Timer restoreTimer: Timer {
        interval: 2000
        running: true
        onTriggered: {
            if (!Backend.preview && (root.panelConfig?.coffeeMode ?? false) && !root.active)
                root.control.inhibit("Nothing KDE · " + Cfg.t("COFFEE MODE"));
            root.restored = true;
        }
    }
    // Plasma's battery applet drives the same switch; keep the saved state honest.
    onActiveChanged: if (restored && panelConfig && panelConfig.coffeeMode !== active) panelConfig.coffeeMode = active
}
