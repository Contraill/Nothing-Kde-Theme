#!/usr/bin/env python3
"""NetworkManager adapter: saved profile identity and verified activation.
No credentials are read or displayed by scan/state/activate.
"""
import json
import os
import re
import subprocess
import sys

ENV={**os.environ,'LC_ALL':'C'}
UUID_RE=re.compile(r'^[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')

def run(*args, timeout=40):
    try:
        return subprocess.run(['nmcli',*args],text=True,capture_output=True,env=ENV,timeout=timeout,check=False)
    except (OSError,subprocess.TimeoutExpired) as e:
        return subprocess.CompletedProcess(args,127,'',str(e))

def fields(line):
    out=[]; current=''; escaped=False
    for ch in line:
        if escaped: current+=ch; escaped=False
        elif ch=='\\': escaped=True
        elif ch==':': out.append(current); current=''
        else: current+=ch
    out.append(current)
    return out

def profile_rows(active=False):
    args=['-t','--escape','yes','-f','UUID,TYPE,DEVICE','connection','show']
    if active: args.append('--active')
    p=run(*args)
    if p.returncode: return []
    rows=[]
    for line in p.stdout.splitlines():
        f=fields(line)
        if len(f)>=3 and f[1] in ('802-11-wireless','wifi') and UUID_RE.fullmatch(f[0]):
            rows.append({'uuid':f[0],'device':f[2]})
    return rows

def profile_ssid(uuid):
    p=run('-g','802-11-wireless.ssid','connection','show','uuid',uuid)
    return p.stdout.strip() if p.returncode==0 else ''

def active_state():
    result=[]
    for profile in profile_rows(True):
        if not profile['device'] or profile['device']=='--': continue
        p=run('-g','GENERAL.STATE','device','show',profile['device'])
        if p.returncode==0 and p.stdout.strip().startswith('100'):
            result.append({**profile,'ssid':profile_ssid(profile['uuid'])})
    return result

def scan():
    profiles=[]
    for p in profile_rows():
        ssid=profile_ssid(p['uuid'])
        if ssid: profiles.append({**p,'ssid':ssid})
    active=active_state()
    p=run('-t','--escape','yes','-f','IN-USE,SSID,SECURITY,SIGNAL','device','wifi','list','--rescan','yes',timeout=20)
    rows=[]; seen={}
    if p.returncode==0:
        for line in p.stdout.splitlines():
            f=fields(line)
            if len(f)<4 or not f[1]: continue
            ssid=f[1]; is_active=f[0] in ('yes','*')
            matches=[v for v in profiles if v['ssid']==ssid]
            active_profile=next((v for v in active if v['ssid']==ssid),None)
            chosen=active_profile or (matches[0] if matches else None)
            item={'ssid':ssid,'security':f[2],'signal':int(f[3]) if f[3].isdigit() else 0,
                  'active':is_active,'saved':bool(chosen),'uuid':chosen['uuid'] if chosen else ''}
            if ssid not in seen:
                seen[ssid]=len(rows); rows.append(item)
            elif is_active or item['signal']>rows[seen[ssid]]['signal']:
                rows[seen[ssid]]=item
    return {'networks':rows,'active':active,'error':p.stderr.strip() if p.returncode else ''}

def activate(uuid):
    if not UUID_RE.fullmatch(uuid): return {'ok':False,'error':'Invalid connection UUID'}
    # Reject arbitrary UUIDs which are not saved Wi-Fi profiles.
    if not any(p['uuid'].lower()==uuid.lower() for p in profile_rows()):
        return {'ok':False,'error':'Saved Wi-Fi profile not found'}
    p=run('--wait','30','connection','up','uuid',uuid,timeout=40)
    active=active_state()
    ok=any(v['uuid'].lower()==uuid.lower() for v in active)
    return {'ok':ok,'active':active,'needsPassword':not ok and bool(re.search(r'secrets? (?:were|was|are) required|no secrets|password.*required',p.stderr,re.I)),
            'error':'' if ok else (p.stderr.strip() or 'Connection is not active')}

def main():
    op=sys.argv[1] if len(sys.argv)>1 else ''
    if op=='scan': result=scan()
    elif op=='state': result={'active':active_state()}
    elif op=='activate' and len(sys.argv)==3: result=activate(sys.argv[2])
    else: raise SystemExit('usage: wifi.py scan|state|activate UUID')
    print(json.dumps(result,ensure_ascii=False))
    return 0

if __name__=='__main__':
    raise SystemExit(main())
