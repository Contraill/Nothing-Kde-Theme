(function () {
    const specs = ['top','bottom'];
    const panels = panelIds.slice().map(id => panelById(id)).filter(p => p && p.type === 'com.nothingplasma.panel');
    const results = specs.map(role => {
        const p = panels.find(p => p.location === role);
        return {role:role,id:p ? p.id : null,location:p ? p.location : null,height:p ? p.height : null,screen:p ? p.screen : null,present:!!p};
    });
    const ok = results.every(p => p.present && p.screen === 0 && p.height===50)
        && !panels.some(p => p.location==='left' || p.location==='right');
    print('NOTHING_LAYOUT_VERIFY:'+JSON.stringify({ok:ok,panels:results}));
})();
