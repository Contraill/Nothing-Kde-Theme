// Idempotent two-panel migration. Remove only retired Nothing side panels;
// preserve top/bottom IDs, widgets, and every other theme's panels.
(function () {
    const type = 'com.nothingplasma.panel';
    const bridgeType = 'com.nothingplasma.launcherbridge';
    const geometry = screenGeometry(0);
    if (!geometry || geometry.width <= 0 || geometry.height <= 0) {
        throw new Error('Primary screen geometry is unavailable; no layout changes made');
    }
    const roles = [
        {role:'top', location:'top', height:50, hiding:'dodgewindows'},
        {role:'bottom', location:'bottom', height:50, hiding:'dodgewindows'}
    ];
    const all = panelIds.slice().map(id => panelById(id)).filter(p => p && p.type === type);
    const used = new Set();
    const created = [];
    const results = [];
    for (const spec of roles) {
        let p = all.find(p => !used.has(p.id) && p.location === spec.location);
        if (!p) {
            p = new Panel(type);
            if (!p) throw new Error('Could not create '+spec.role+' panel');
            created.push(p.id);
        }
        used.add(p.id);
        p.screen = 0;
        p.currentConfigGroup = ['General'];
        p.writeConfig('panelRole', spec.role);
        if (spec.role === 'top' || spec.role === 'bottom') {
            p.writeConfig('horizontalPanelHeight', 50);
        }
        p.reloadConfig();
        p.location = spec.location;
        p.alignment = 'center';
        p.offset = 0;
        p.lengthMode = 'fit';
        p.minimumLength = 1;
        p.maximumLength = 10000;
        p.height = spec.height;
        p.hiding = spec.hiding;
        p.floating = false;
        if (spec.role === 'top') {
            if (!p.widgets('org.kde.plasma.notifications').length) {
                p.addWidget('org.kde.plasma.notifications');
            }
            if (typeof knownWidgetTypes !== 'undefined'
                && knownWidgetTypes.includes('com.nothingplasma.notificationbridge')
                && !p.widgets('com.nothingplasma.notificationbridge').length) {
                p.addWidget('com.nothingplasma.notificationbridge');
            }
        }
        if (spec.role === 'bottom') {
            const existing = p.widgets(bridgeType);
            if (!existing || existing.length === 0) {
                const bridge = p.addWidget(bridgeType);
                if (!bridge) throw new Error('Could not attach launcher bridge');
            }
        }
        results.push({role:spec.role,id:p.id,location:p.location,height:p.height,screen:p.screen,created:created.indexOf(p.id)!==-1});
    }
    const retired = all.filter(p => p.location === 'left' || p.location === 'right');
    const removed = retired.map(p => p.id);
    for (const p of retired) p.remove();
    print('NOTHING_LAYOUT_REMOVED:'+JSON.stringify(removed));
    print('NOTHING_LAYOUT_STATE:'+JSON.stringify(results));
    print('NOTHING_LAYOUT_CREATED:'+JSON.stringify(created));
})();
