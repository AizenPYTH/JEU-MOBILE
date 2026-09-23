#!/usr/bin/env bash
# Regenerates BistroUI's Sketches.xcassets from the design handoff in docs/design.
# Needs python3, node and Playwright (preinstalled in Claude Code cloud containers).
# The sketches are placeholders; final illustrations go into Bistro/Assets.xcassets and win automatically.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)"
python3 "$ROOT/scripts/design/extract_sketches.py" "$ROOT/docs/design" "$WORK"
(cd "$WORK" && NODE_PATH="$(npm root -g)" node "$ROOT/scripts/design/render_sketches.js")
CATALOG="$ROOT/BistroKit/Sources/BistroUI/Resources/Sketches.xcassets"
python3 - "$WORK" "$CATALOG" <<'PY'
import json, os, shutil, sys
work, catalog = sys.argv[1], sys.argv[2]
meta = json.load(open(os.path.join(work, 'meta.json')))
for name in meta:
    d = os.path.join(catalog, name + '.imageset'); os.makedirs(d, exist_ok=True)
    for s in (2, 3):
        shutil.copy(os.path.join(work, 'png', f'{name}@{s}x.png'), os.path.join(d, f'{name}@{s}x.png'))
    json.dump({"images": [{"idiom": "universal", "scale": "1x"},
                          {"filename": f"{name}@2x.png", "idiom": "universal", "scale": "2x"},
                          {"filename": f"{name}@3x.png", "idiom": "universal", "scale": "3x"}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(d, 'Contents.json'), 'w'), indent=2)
print(f"{len(meta)} sketches exported to {catalog}")
PY
rm -rf "$WORK"
