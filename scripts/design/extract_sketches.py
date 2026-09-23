"""Extracts the vector sketches of the design handoff (docs/design) into standalone SVGs.

Each sketch is a <g id="<asset name>"> in the handoff pages, already named with the asset
convention (ing_tomato, char_margot_idle…). Output: <out>/svg/*.svg + <out>/meta.json (size in pt).
Usage: python3 extract_sketches.py <docs/design dir> <out dir>
"""
import sys, os
DESIGN, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT + '/svg', exist_ok=True)
os.chdir(OUT)
import re, json
def find_element(s, start):
    # s[start] is '<g ...' ; return end index after matching </g>
    depth=0; i=start
    tag=re.compile(r'<(/?)g\b[^>]*?(/?)>')
    for m in tag.finditer(s, start):
        if m.group(1)=='/': depth-=1
        elif m.group(2)=='/': pass
        else: depth+=1
        if depth==0: return m.end()
    raise Exception('unbalanced')
def defs_of(s):
    # shared filter / patterns
    out=[]
    for tag in ['filter','pattern']:
        for m in re.finditer(r'<%s id="([^"]+)".*?</%s>'%(tag,tag), s, re.S):
            out.append(m.group(0))
    return out
assets={}
sources={'Bistro Assets.dc.html':None,'Bistro Labo.dc.html':['ui_lab_pot']}
for f,only in sources.items():
    s=open(os.path.join(DESIGN, f),encoding='utf-8').read()
    d=defs_of(s)
    vbs=dict((i,vb) for vb,i in re.findall(r'<svg[^>]*viewBox="([^"]+)"[^>]*>\s*<use[^>]*href="#([a-z_0-9]+)"',s))
    for m in re.finditer(r'<g id="([a-z_0-9]+)"',s):
        i=m.group(1)
        if only and i not in only: continue
        if i in assets or i not in vbs: continue
        g=s[m.start():find_element(s,m.start())]
        # dedupe defs ids
        seen=set(); dd=[]
        for x in d:
            k=re.match(r'<\w+ id="([^"]+)"',x).group(1)
            if k not in seen: seen.add(k); dd.append(x)
        assets[i]=(vbs[i],dd,g)
base={'ing':(96,96),'dish':(176,176),'char':(200,260),'staff':(200,260),'station':(160,140),'deco':(120,120),'ui':(150,128)}
meta={}
def with_deps(i, seen=None):
    seen = seen or []
    if i in seen: return seen
    seen.append(i)
    for dep in re.findall(r'href="#([a-z_0-9]+)"', assets[i][2]):
        if dep in assets: with_deps(dep, seen)
    return seen
for i,(vb,dd,g) in assets.items():
    g=''.join(assets[k][2] for k in with_deps(i))
    x,y,w,h=map(float,vb.split())
    cat=i.split('_')[0]
    if i.endswith('_portrait'): bw,bh=120,round(120*h/w)
    else: bw,bh=base[cat]
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="{vb}" width="{bw}" height="{bh}"><defs>{"".join(dd)}{g}</defs><use href="#{i}"/></svg>'
    open(f'svg/{i}.svg','w').write(svg)
    meta[i]=(bw,bh)
json.dump(meta,open('meta.json','w'),indent=0)
print(len(meta))
