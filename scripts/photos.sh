#!/bin/bash
# Photo asset pipeline — see docs/photo_pipeline/PHOTO_PIPELINE.md
#   ./scripts/photos.sh audit|search|download|process|validate|report|status|all [--dry-run] [--offline]
# Key (never committed): PEXELS_API_KEY in the environment; without it only Openverse is searched.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -c "import PIL" 2>/dev/null || python3 -m pip install --quiet "pillow>=10"
exec python3 scripts/photos/pipeline.py "$@"
