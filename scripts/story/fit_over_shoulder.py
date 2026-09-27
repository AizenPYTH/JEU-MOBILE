import json, math, glob, os, sys

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'ScreenshotKit', 'Sources', 'StoryLibrary', 'Resources', 'Story') + os.sep
locs = {l['id']: l for l in json.load(open(R + 'locations.json'))['locations']}
npcs = {n['id']: n for n in json.load(open(R + 'npcs.json'))['npcs']}
scenes = [s for f in sorted(glob.glob(R + 'scenes/*.json')) for s in json.load(open(f))['scenes']]
ASPECT = 390 / 844
def head(actor, a):
    h = 1.74 if actor == 'player' else npcs[actor].get('height', 1.75)
    return (a['x'], (1.66 - (0.42 if a.get('seated') else 0)) * h / 1.75 + 0.02, a['z'])
def frame(c, p, focal):
    fx, fy, fz = c[3]-c[0], c[4]-c[1], c[5]-c[2]
    n = math.sqrt(fx*fx+fy*fy+fz*fz); fx, fy, fz = fx/n, fy/n, fz/n
    rx, rz = -fz, fx; rn = math.hypot(rx, rz)
    if rn < 1e-6: return None
    rx, rz = rx/rn, rz/rn
    ux, uy, uz = -rz*fy, rz*fx - rx*fz, rx*fy
    dx, dy, dz = p[0]-c[0], p[1]-c[1], p[2]-c[2]
    depth = dx*fx+dy*fy+dz*fz
    if depth <= 0.05: return None
    th = math.tan(math.atan(18/focal)); tw = th*ASPECT
    return (dx*rx+dz*rz)/depth/tw, (dx*ux+dy*uy+dz*uz)/depth/th, depth, 0.25/(2*th*depth)
targets = {}   # camera id -> list of (subject head, other head, all heads)
for s in scenes:
    loc = locs[s['location']]; A = {a['id']: a for a in loc['anchors']}
    pos = {}
    for b in s['beats']:
        if b['kind'] in ('place','enter','move') and b.get('anchor') in A: pos[b['actor']] = A[b['anchor']]
        if b['kind'] == 'camera' and b['shot']['kind'] == 'overShoulder':
            sh = b['shot']; sub, oth = sh.get('subject'), sh.get('other')
            if sub in pos and oth in pos:
                targets.setdefault((s['location'], sh['camera']), []).append((head(sub, pos[sub]), head(oth, pos[oth])))
for (lid, cid), cases in targets.items():
    loc = locs[lid]; w, d, h = loc['size']; cam = next(c for c in loc['cameras'] if c['id'] == cid)
    focal = cam.get('focal', 50); best = None
    oth = cases[0][1]; sub = cases[0][0]
    for xi in range(-60, 61):
        for zi in range(-60, 61):
            x = sub[0] + xi*0.025; z = sub[2] + zi*0.025
            if abs(x) > w/2-0.15 or abs(z) > d/2-0.15: continue
            for y in (sub[1]+0.02, sub[1]+0.08):
                c = (x, y, z, oth[0], oth[1]-0.05, oth[2])
                ok = True; score = 0
                for s_, o_ in cases:
                    fs = frame(c, s_, focal); fo = frame(c, o_, focal)
                    if not fs or not fo: ok = False; break
                    sx, sy, dep, share = fs
                    if not (0.8 < abs(sx) < 1.2 and 0.15 < share < 0.45 and dep > 0.55): ok = False; break
                    if abs(fo[0]) > 0.45 or abs(fo[1]) > 0.6: ok = False; break
                if not ok: continue
                score = math.dist((x, z), (cam['x'], cam['z']))
                if best is None or score < best[0]: best = (score, c)
    if best:
        c = best[1]
        print(f'"{cid}": ({c[0]:.3f}, {c[1]:.3f}, {c[2]:.3f}, {c[3]:.3f}, {c[4]:.3f}, {c[5]:.3f}),  # moved {best[0]:.2f} m')
    else:
        print(f'# {cid}: no fit')
