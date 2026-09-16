// Read-only inventory for the bounded live appearance test. No persistent script.
for (const w of workspace.windowList()) {
    if (w.resourceClass === "dolphin" || w.resourceClass === "kate" || w.resourceClass === "systemsettings")
        print("NOTHING_GLASS_WINDOW " + JSON.stringify({pid:w.pid, caption:w.caption,
            resourceClass:w.resourceClass, active:w.active, opacity:w.opacity,
            alphaDecoration:w.decorationHasAlpha, geometry:w.frameGeometry}));
}
