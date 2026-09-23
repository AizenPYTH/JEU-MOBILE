#!/usr/bin/env bash
# Lance les tests du moteur (GameCore + données JSON) puis le simulateur.
# Fonctionne sur macOS (Xcode installé) et sur Linux (voir setup-linux-swift.sh).
set -euo pipefail
cd "$(dirname "$0")/../BistroKit"
swift test
swift run BalanceSim
