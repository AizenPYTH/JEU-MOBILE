#!/usr/bin/env bash
# Installe une toolchain Swift 6.0 dans /opt/swift sur Ubuntu 24.04 (conteneurs cloud sans Xcode),
# à partir des paquets Ubuntu officiels. Ne sert qu'à compiler/tester CaseEngine, CaseLibrary et CaseLint ;
# l'app iOS (ScreenshotUI) nécessite Xcode (ou le workflow macOS).
#
# Ensuite :  export PATH=/opt/swift/usr/libexec/swift/bin:$PATH
#            export LD_LIBRARY_PATH=/opt/swift/usr/lib/x86_64-linux-gnu
set -euo pipefail
[ -x /opt/swift/usr/libexec/swift/bin/swift ] && { echo "Swift déjà installé dans /opt/swift"; exit 0; }
TMP=$(mktemp -d)
UB=http://archive.ubuntu.com/ubuntu/pool
for f in universe/s/swiftlang/swiftlang_6.0.3-2build1_amd64.deb \
         universe/s/swiftlang/libswiftlang_6.0.3-2build1_amd64.deb \
         main/libx/libxml2/libxml2-16_2.14.5+dfsg-0.2_amd64.deb; do
  curl -fsSL -o "$TMP/$(basename "$f")" "$UB/$f"
done
mkdir -p /opt/swift
for deb in "$TMP"/*.deb; do dpkg-deb -x "$deb" /opt/swift; done
rm -rf "$TMP"
PATH=/opt/swift/usr/libexec/swift/bin:$PATH LD_LIBRARY_PATH=/opt/swift/usr/lib/x86_64-linux-gnu swift --version
