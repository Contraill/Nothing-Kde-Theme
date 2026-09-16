// Nothing KDE: top island and bottom dock.
function configureRole(panel, role, location, thickness, hiding) {
    panel.location = location;
    panel.alignment = "center";
    panel.offset = 0;
    panel.lengthMode = "fit";
    panel.minimumLength = 1;
    panel.maximumLength = 10000;
    panel.height = thickness;
    panel.hiding = hiding;
    panel.floating = false;
    panel.currentConfigGroup = ["General"];
    panel.writeConfig("panelRole", role);
    panel.reloadConfig();
}

var topPanel = new Panel("com.nothingplasma.panel");
configureRole(topPanel, "top", "top", 50, "dodgewindows");
topPanel.addWidget("org.kde.plasma.notifications");
if (knownWidgetTypes.includes("com.nothingplasma.notificationbridge")) {
    topPanel.addWidget("com.nothingplasma.notificationbridge");
}

var bottomPanel = new Panel("com.nothingplasma.panel");
configureRole(bottomPanel, "bottom", "bottom", 50, "dodgewindows");
bottomPanel.addWidget("com.nothingplasma.launcherbridge");

