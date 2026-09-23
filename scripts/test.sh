#!/usr/bin/env bash
# Runs the engine and case tests, then validates every case with CaseLint.
# Works on macOS (Xcode installed) and on Linux (see setup-linux-swift.sh).
set -euo pipefail
cd "$(dirname "$0")/../ScreenshotKit"
swift test
swift run CaseLint
