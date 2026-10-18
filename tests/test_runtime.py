import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT=Path(__file__).resolve().parents[1]

def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

manage=load('nothing_notification_restore',ROOT/'notification-skin/restore-legacy.py')

class NotificationTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        base=Path(self.tmp.name)
        self.dst=base/'plasma/plasmoids/org.kde.plasma.notifications'
        self.backup=base/'nothing-plasma/backups/org.kde.plasma.notifications.pre-nothing'
        self.patches=[mock.patch.object(manage,'DST',self.dst),mock.patch.object(manage,'BACKUP',self.backup)]
        for p in self.patches: p.start();self.addCleanup(p.stop)

    def test_restore_does_not_touch_unmarked_override(self):
        self.dst.mkdir(parents=True)
        (self.dst/'user-file').write_text('preserve')
        manage.restore()
        self.assertEqual((self.dst/'user-file').read_text(),'preserve')

    def test_restore_removes_only_marked_overlay_and_recovers_backup(self):
        self.dst.mkdir(parents=True)
        (self.dst/manage.MARKER).write_text('old Nothing overlay')
        self.backup.mkdir(parents=True)
        (self.backup/'user-file').write_text('preserve')
        manage.restore()
        self.assertEqual((self.dst/'user-file').read_text(),'preserve')
        self.assertFalse(self.backup.exists())

class LayoutTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('node'),'Node.js is not installed')
    def test_repair_is_idempotent_and_preserves_foreign_panels(self):
        script=r'''const fs=require('fs'),vm=require('vm'),assert=require('assert');
const code=fs.readFileSync(process.argv[2],'utf8');
const verify=fs.readFileSync(process.argv[3],'utf8');
let next=1,panels=[],logs=[];
function Panel(type){this.id=next++;this.type=type;this.location='bottom';this.screen=0;this.items=[];this.values={};panels.push(this);}
Panel.prototype.writeConfig=function(k,v){this.values[k]=v};
Panel.prototype.reloadConfig=function(){};
Panel.prototype.widgets=function(t){return this.items.filter(w=>w.type===t)};
Panel.prototype.addWidget=function(t){let w={id:next++,type:t,values:{},writeConfig(k,v){this.values[k]=v},reloadConfig(){}};this.items.push(w);return w};
Panel.prototype.remove=function(){assert.equal(this.type,'com.nothingplasma.panel');assert(['left','right'].includes(this.location));panels=panels.filter(p=>p!==this)};
const ctx={Panel,screenGeometry:()=>({width:1920,height:1080}),panelById:id=>panels.find(p=>p.id===id),print:s=>logs.push(s),Set,JSON,Math};
Object.defineProperty(ctx,'panelIds',{get:()=>panels.map(p=>p.id)});
function run(){logs=[];vm.runInNewContext(code,ctx);return JSON.parse(logs.find(s=>s.startsWith('NOTHING_LAYOUT_STATE:')).split(':').slice(1).join(':'))}
function check(){logs=[];vm.runInNewContext(verify,ctx);return JSON.parse(logs.find(s=>s.startsWith('NOTHING_LAYOUT_VERIFY:')).split(':').slice(1).join(':'))}
let foreign=new Panel('org.kde.plasma.panel');foreign.location='top';let foreignId=foreign.id;
let left=new Panel('com.nothingplasma.panel');left.location='left';
let right=new Panel('com.nothingplasma.panel');right.location='right';
let foreignSide=new Panel('org.kde.plasma.panel');foreignSide.location='left';
let first=run();assert.equal(first.length,2);assert.equal(panels.length,4);assert.equal(check().ok,true);
assert(panels.includes(foreignSide));assert(!panels.includes(left));assert(!panels.includes(right));
let top=panels.find(p=>p.type==='com.nothingplasma.panel'&&p.location==='top');
let tray=top.widgets('org.kde.plasma.systemtray')[0];
assert(tray);assert.equal(tray.values.extraItems.length,0);
tray.values.hiddenItems=['custom-app'];tray.values.extraItems=['user-widget'];
let ids=first.map(p=>p.id);let second=run();
assert.equal(top.widgets('org.kde.plasma.systemtray').length,1);
assert.deepEqual(tray.values.hiddenItems,['custom-app']);assert.deepEqual(tray.values.extraItems,['user-widget']);assert.deepEqual(second.map(p=>p.id),ids);assert.equal(panels.length,4);
assert.equal(panels[0].id,foreignId);
assert.equal(panels.filter(p=>p.type==='com.nothingplasma.panel').find(p=>p.location==='bottom').widgets('com.nothingplasma.launcherbridge').length,1);
panels=panels.filter(p=>p.type!=='com.nothingplasma.panel'||(p.location!=='top'&&p.location!=='right'));
let repaired=run();assert.equal(repaired.length,2);assert.equal(check().ok,true);
assert.equal(repaired.find(p=>p.role==='bottom').id,ids[1]);
assert.equal(panels.filter(p=>p.type==='com.nothingplasma.panel').length,2);
console.log('PASS: two roles, 50px, idempotence, retired rails removed, foreign panels and dock preserved');'''
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/'test.js';path.write_text(script)
            p=subprocess.run(['node',str(path),str(ROOT/'runtime/ensure-panels.js'),str(ROOT/'runtime/verify-panels.js')],text=True,capture_output=True)
            self.assertEqual(p.returncode,0,p.stderr)

    def test_layout_repair_is_opt_in_and_backed_up(self):
        install=(ROOT/'install.sh').read_text()
        self.assertIn('runtime/ensure-panels.js',install)
        self.assertIn('if (( APPLY_LAYOUT )); then',install)
        self.assertIn('Pre-migration backup',install)
        for path in ROOT.glob('plasma/**/layout.js'):
            if 'com.nothingplasma.island.panel' in str(path):
                text=path.read_text()
                self.assertIn('"top", "top", 50',text)
                self.assertIn('"bottom", "bottom", 50',text)

if __name__=='__main__': unittest.main()
