# Workflows GitHub Actions

Les trois workflows sont dans `.github/workflows/` (branche `claude/busy-hopper-5dgev5`). Ce document
garde leur contenu de référence. Pour que Claude puisse les modifier, la connexion GitHub
(https://claude.ai/connect-github) doit avoir l'accès aux workflows ; sinon le push est refusé
(« refusing to allow an OAuth App to create or update workflow … without `workflow` scope ») et il
faut les modifier à la main sur GitHub.

| Fichier | Rôle | Déclencheur |
|---|---|---|
| `ios-build.yml` | Compile l'app (interface comprise) pour le simulateur, sans signature | chaque push touchant l'app + manuel |
| `tests-linux.yml` | Tests du moteur + CaseLint (Linux, peu coûteux) | chaque push |
| `ios-testflight.yml` | Tests, archive signée, envoi TestFlight | manuel + PR vers `main` |


## `.github/workflows/ios-build.yml`

```yaml
# Compiles the iOS app (ScreenshotUI included) for the simulator on every push that touches the app,
# then plays the main path on a simulator (ScreenshotUITests) and keeps a screenshot of every step.
# No signing, no upload. Compiler errors and test failures are listed in the job summary; the build
# log, the test result bundle and the screenshots are kept as artifacts.
name: iOS – Compile

on:
  push:
    paths:
      - "ScreenshotKit/**"
      - "Screenshot/**"
      - "ScreenshotUITests/**"
      - "Screenshot.xcodeproj/**"
      - "Configs/**"
      - ".github/workflows/ios-build.yml"
  workflow_dispatch:

permissions:
  contents: write   # publishes the UI test screenshots to the ci/ui-screenshots branch

concurrency:
  group: ios-compile-${{ github.ref }}
  cancel-in-progress: true

jobs:
  compile:
    runs-on: ${{ vars.MACOS_RUNNER || 'macos-15' }}
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: |
          if [ -n "${{ vars.XCODE_VERSION }}" ]; then
            XCODE="/Applications/Xcode_${{ vars.XCODE_VERSION }}.app"
          else
            XCODE=$(ls -d /Applications/Xcode_*.app | grep -viE 'beta|rc|release_candidate' | sort -V | tail -1)
          fi
          echo "Using $XCODE"
          sudo xcode-select -s "$XCODE/Contents/Developer"
          xcodebuild -version

      - name: Build for the iOS simulator
        run: |
          set +e
          xcodebuild build \
            -project Screenshot.xcodeproj -scheme Screenshot -configuration Debug \
            -destination 'generic/platform=iOS Simulator' \
            -skipPackagePluginValidation \
            CODE_SIGNING_ALLOWED=NO > "$RUNNER_TEMP/build.log" 2>&1
          status=$?
          set -e
          grep -E "error:|warning:" "$RUNNER_TEMP/build.log" | grep -v "^ld: warning" | sort -u > "$RUNNER_TEMP/diagnostics.txt" || true
          echo "### iOS compile: $( [ $status -eq 0 ] && echo OK || echo FAILED )" >> "$GITHUB_STEP_SUMMARY"
          echo '```' >> "$GITHUB_STEP_SUMMARY"
          grep "error:" "$RUNNER_TEMP/diagnostics.txt" | head -200 >> "$GITHUB_STEP_SUMMARY" || true
          echo '```' >> "$GITHUB_STEP_SUMMARY"
          echo "---- diagnostics ----"
          cat "$RUNNER_TEMP/diagnostics.txt"
          echo "---- tail ----"
          tail -60 "$RUNNER_TEMP/build.log"
          exit $status

      - name: Pick an iPhone simulator
        id: sim
        run: |
          UDID=$(xcrun simctl list devices available -j | python3 -c '
          import json, sys
          devices = json.load(sys.stdin)["devices"]
          ios = sorted((r for r in devices if "iOS" in r), key=lambda r: [int(x) for x in r.split("iOS-")[-1].split("-")])
          for runtime in reversed(ios):
              for d in devices[runtime]:
                  if d["name"].startswith("iPhone") and "Pro" not in d["name"] and "Plus" not in d["name"] and "Max" not in d["name"]:
                      print(d["udid"]); sys.exit()
          ')
          echo "Simulator: $UDID"
          xcrun simctl list devices | grep "$UDID" || true
          echo "udid=$UDID" >> "$GITHUB_OUTPUT"
          # Boot it now and wait until it is fully up: a cold boot during the test times out the launch.
          xcrun simctl boot "$UDID" || true
          xcrun simctl bootstatus "$UDID" -b

      - name: UI tests on the simulator (main path)
        run: |
          set +e
          xcodebuild test \
            -project Screenshot.xcodeproj -scheme Screenshot -configuration Debug \
            -destination "id=${{ steps.sim.outputs.udid }}" \
            -resultBundlePath "$RUNNER_TEMP/UITests.xcresult" \
            -skipPackagePluginValidation > "$RUNNER_TEMP/uitests.log" 2>&1
          status=$?
          set -e
          echo "### UI tests: $( [ $status -eq 0 ] && echo PASSED || echo FAILED )" >> "$GITHUB_STEP_SUMMARY"
          echo '```' >> "$GITHUB_STEP_SUMMARY"
          grep -E "Test Case .*(passed|failed)|error:|XCTAssert|Missing:|crash|Crash" "$RUNNER_TEMP/uitests.log" | head -80 >> "$GITHUB_STEP_SUMMARY" || true
          echo '```' >> "$GITHUB_STEP_SUMMARY"
          echo "---- results ----"
          grep -E "Test Case .*(passed|failed)|error:|Missing:|crash|Crash|Executed" "$RUNNER_TEMP/uitests.log" | head -120
          echo "---- tail ----"
          tail -40 "$RUNNER_TEMP/uitests.log"
          mkdir -p "$RUNNER_TEMP/screenshots"
          xcrun xcresulttool export attachments --path "$RUNNER_TEMP/UITests.xcresult" --output-path "$RUNNER_TEMP/screenshots" || true
          ls "$RUNNER_TEMP/screenshots" | head -80
          exit $status

      - name: Publish the screenshots to the ci/ui-screenshots branch
        if: always()
        run: |
          OUT="$RUNNER_TEMP/publish"
          rm -rf "$OUT" && mkdir -p "$OUT"
          python3 - "$RUNNER_TEMP/screenshots" "$OUT" <<'PY'
          import json, os, shutil, sys
          src, out = sys.argv[1], sys.argv[2]
          manifest = os.path.join(src, "manifest.json")
          if os.path.exists(manifest):
              for test in json.load(open(manifest)):
                  prefix = test["testIdentifier"].split("/")[-1].replace("()", "")
                  for a in test.get("attachments", []):
                      name = a.get("suggestedHumanReadableName", "").split("_0_")[0]
                      f = a["exportedFileName"]
                      if f.endswith(".png"):
                          shutil.copy(os.path.join(src, f), os.path.join(out, f"{prefix}--{name}.png"))
          PY
          grep -E "Test Case .*(passed|failed)|error:|Missing:|XCTAssert|crash|Crash|Executed" "$RUNNER_TEMP/uitests.log" > "$OUT/results.txt" || true
          echo "commit ${{ github.sha }}" >> "$OUT/results.txt"
          cd "$OUT"
          git init -q -b ci/ui-screenshots
          git config user.name "github-actions"
          git config user.email "github-actions@users.noreply.github.com"
          git add -A
          git commit -q -m "UI test screenshots for ${{ github.sha }}"
          git push -q -f "https://x-access-token:${{ github.token }}@github.com/${{ github.repository }}.git" ci/ui-screenshots

      - name: Keep the UI test screenshots
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: ui-screenshots
          path: ${{ runner.temp }}/screenshots
          retention-days: 14

      - name: Keep the UI test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: ui-test-results
          path: |
            ${{ runner.temp }}/uitests.log
            ${{ runner.temp }}/UITests.xcresult
          retention-days: 7

      - name: Keep the build log
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: ios-build-log
          path: ${{ runner.temp }}/build.log
          retention-days: 7
```

## `.github/workflows/tests-linux.yml`

```yaml
# Engine tests on Linux (cheap): CaseEngine + case validation (JSON) + CaseLint.
# Runs on every push. The iOS UI is compiled on macOS by ios-build.yml.
name: Tests (Linux)

on:
  push:
  workflow_dispatch:

concurrency:
  group: tests-linux-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    # Official Swift image (Docker Hub "swift"), same major version as Xcode's toolchain.
    container: swift:6.0-noble
    steps:
      - uses: actions/checkout@v4

      - name: Cache SwiftPM build
        uses: actions/cache@v4
        with:
          path: ScreenshotKit/.build
          key: spm-linux-${{ hashFiles('ScreenshotKit/Package.swift') }}-${{ github.sha }}
          restore-keys: spm-linux-${{ hashFiles('ScreenshotKit/Package.swift') }}-

      - name: Run tests
        working-directory: ScreenshotKit
        run: swift test

      - name: Validate the cases (CaseLint)
        working-directory: ScreenshotKit
        run: swift run CaseLint
```

## `.github/workflows/ios-testflight.yml`

```yaml
# Full iOS build on macOS: all tests, archive, signing, upload to TestFlight.
#
# Triggers (macOS minutes are expensive, so NOT on every push):
#   - manually: Actions > "iOS – Build & TestFlight" > Run workflow
#   - on pull requests targeting main
#
# Required repository secrets (see docs/TESTFLIGHT_SETUP.md):
#   APPLE_DIST_CERT_P12_BASE64  Apple Distribution certificate + private key (.p12), base64
#   APPLE_DIST_CERT_PASSWORD    password of that .p12
#   APPLE_PROFILE_BASE64        App Store provisioning profile (.mobileprovision), base64
#   ASC_KEY_ID                  App Store Connect API key id
#   ASC_ISSUER_ID               App Store Connect API issuer id
#   ASC_KEY_P8                  content of the AuthKey_XXXX.p8 file
# Optional repository variables:
#   MACOS_RUNNER          runner label (default macos-15)
#   XCODE_VERSION         e.g. "16.4" to pin Xcode (default: newest stable on the runner)
#   BUILD_NUMBER_OFFSET   added to the run number (use it if TestFlight already has higher builds)
#
# Without the secrets (e.g. PR from a fork), the job still runs the tests and makes an unsigned
# Release archive (checks bundle id, version, build number, privacy manifest), then stops.
name: iOS – Build & TestFlight

on:
  workflow_dispatch:
  pull_request:
    branches: [main]

concurrency:
  group: ios-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: ${{ vars.MACOS_RUNNER || 'macos-15' }}
    timeout-minutes: 60
    env:
      APPLE_DIST_CERT_P12_BASE64: ${{ secrets.APPLE_DIST_CERT_P12_BASE64 }}
      APPLE_DIST_CERT_PASSWORD: ${{ secrets.APPLE_DIST_CERT_PASSWORD }}
      APPLE_PROFILE_BASE64: ${{ secrets.APPLE_PROFILE_BASE64 }}
      ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
      ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
      ASC_KEY_P8: ${{ secrets.ASC_KEY_P8 }}
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: |
          if [ -n "${{ vars.XCODE_VERSION }}" ]; then
            XCODE="/Applications/Xcode_${{ vars.XCODE_VERSION }}.app"
          else
            XCODE=$(ls -d /Applications/Xcode_*.app | grep -viE 'beta|rc|release_candidate' | sort -V | tail -1)
          fi
          echo "Using $XCODE"
          sudo xcode-select -s "$XCODE/Contents/Developer"
          xcodebuild -version
          swift --version

      - name: Tests (CaseEngine, cases; ScreenshotUI compiles for iOS in the archive step)
        working-directory: ScreenshotKit
        run: swift test

      - name: Check signing secrets
        id: secrets
        run: |
          missing=""
          for name in APPLE_DIST_CERT_P12_BASE64 APPLE_DIST_CERT_PASSWORD APPLE_PROFILE_BASE64 ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8; do
            if [ -z "${!name}" ]; then missing="$missing $name"; fi
          done
          if [ -n "$missing" ]; then
            echo "::warning::Missing secrets:$missing — building for the simulator only, no TestFlight upload."
            echo "can_sign=false" >> "$GITHUB_OUTPUT"
          else
            echo "can_sign=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Archive without signing (checks the Release archive before the secrets exist)
        if: steps.secrets.outputs.can_sign != 'true'
        run: |
          set -o pipefail
          xcodebuild archive \
            -project Screenshot.xcodeproj -scheme Screenshot -configuration Release \
            -destination 'generic/platform=iOS' \
            -archivePath "$RUNNER_TEMP/Unsigned.xcarchive" \
            CURRENT_PROJECT_VERSION="$(( ${{ github.run_number }} + ${{ vars.BUILD_NUMBER_OFFSET || 0 }} )).${{ github.run_attempt }}" \
            CODE_SIGNING_ALLOWED=NO \
            | tee "$RUNNER_TEMP/archive.log" | grep -E "error:|ARCHIVE" || true
          grep -q "ARCHIVE SUCCEEDED" "$RUNNER_TEMP/archive.log" || { tail -100 "$RUNNER_TEMP/archive.log"; exit 1; }
          APP="$RUNNER_TEMP/Unsigned.xcarchive/Products/Applications/Screenshot.app"
          PLIST="$APP/Info.plist"
          PB=/usr/libexec/PlistBuddy
          {
            echo "### Unsigned Release archive: OK (no signing secrets yet)"
            echo "| Key | Value |"
            echo "|---|---|"
            for key in CFBundleIdentifier CFBundleDisplayName CFBundleShortVersionString CFBundleVersion MinimumOSVersion ITSAppUsesNonExemptEncryption UIRequiresFullScreen; do
              echo "| $key | $($PB -c "Print :$key" "$PLIST" 2>/dev/null || echo '—') |"
            done
            echo "| PrivacyInfo.xcprivacy | $([ -f "$APP/PrivacyInfo.xcprivacy" ] && echo present || echo MISSING) |"
            echo "| App icon | $(ls "$APP" | grep -c '^AppIcon') file(s) |"
          } >> "$GITHUB_STEP_SUMMARY"
          cat "$GITHUB_STEP_SUMMARY"
          [ -f "$APP/PrivacyInfo.xcprivacy" ] || { echo "::error::PrivacyInfo.xcprivacy is missing from the app bundle"; exit 1; }

      - name: Install certificate and provisioning profile
        if: steps.secrets.outputs.can_sign == 'true'
        id: signing
        run: |
          set -euo pipefail
          KEYCHAIN="$RUNNER_TEMP/signing.keychain-db"
          KEYCHAIN_PASSWORD=$(openssl rand -base64 24)

          # Temporary keychain holding the distribution certificate.
          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
          security set-keychain-settings -lut 21600 "$KEYCHAIN"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
          echo "$APPLE_DIST_CERT_P12_BASE64" | base64 --decode > "$RUNNER_TEMP/dist.p12"
          security import "$RUNNER_TEMP/dist.p12" -P "$APPLE_DIST_CERT_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN"
          curl -fsSL https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer -o "$RUNNER_TEMP/wwdr.cer"
          security import "$RUNNER_TEMP/wwdr.cer" -k "$KEYCHAIN" || true
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" > /dev/null
          security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | tr -d '"')
          echo "Identities:"; security find-identity -v -p codesigning "$KEYCHAIN"

          # Provisioning profile: read its name, UUID, team and app id.
          echo "$APPLE_PROFILE_BASE64" | base64 --decode > "$RUNNER_TEMP/profile.mobileprovision"
          security cms -D -i "$RUNNER_TEMP/profile.mobileprovision" > "$RUNNER_TEMP/profile.plist"
          PB=/usr/libexec/PlistBuddy
          PROFILE_NAME=$($PB -c 'Print :Name' "$RUNNER_TEMP/profile.plist")
          PROFILE_UUID=$($PB -c 'Print :UUID' "$RUNNER_TEMP/profile.plist")
          TEAM_ID=$($PB -c 'Print :TeamIdentifier:0' "$RUNNER_TEMP/profile.plist")
          APP_ID=$($PB -c 'Print :Entitlements:application-identifier' "$RUNNER_TEMP/profile.plist")
          BUNDLE_ID=$(grep -E '^PRODUCT_BUNDLE_IDENTIFIER' Configs/Screenshot.xcconfig | cut -d= -f2 | xargs)
          echo "Profile: $PROFILE_NAME ($PROFILE_UUID) team $TEAM_ID app $APP_ID"
          if [ "$APP_ID" != "$TEAM_ID.$BUNDLE_ID" ]; then
            echo "::error::The provisioning profile is for '$APP_ID' but the app bundle id is '$BUNDLE_ID' (Configs/Screenshot.xcconfig)."
            exit 1
          fi
          for dir in "$HOME/Library/MobileDevice/Provisioning Profiles" "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
            mkdir -p "$dir"
            cp "$RUNNER_TEMP/profile.mobileprovision" "$dir/$PROFILE_UUID.mobileprovision"
          done

          # App Store Connect API key (used by the upload).
          mkdir -p "$HOME/.appstoreconnect/private_keys"
          printf '%s\n' "$ASC_KEY_P8" > "$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"

          echo "profile_name=$PROFILE_NAME" >> "$GITHUB_OUTPUT"
          echo "team_id=$TEAM_ID" >> "$GITHUB_OUTPUT"
          echo "bundle_id=$BUNDLE_ID" >> "$GITHUB_OUTPUT"

      - name: Compute build number
        if: steps.secrets.outputs.can_sign == 'true'
        id: version
        run: |
          # Unique and always increasing: <run number + offset>.<attempt>, e.g. 42.1 then 42.2 on a re-run.
          BUILD_NUMBER="$(( ${{ github.run_number }} + ${{ vars.BUILD_NUMBER_OFFSET || 0 }} )).${{ github.run_attempt }}"
          echo "build_number=$BUILD_NUMBER" >> "$GITHUB_OUTPUT"
          echo "Build number: $BUILD_NUMBER"

      - name: Archive
        if: steps.secrets.outputs.can_sign == 'true'
        run: |
          set -o pipefail
          xcodebuild archive \
            -project Screenshot.xcodeproj -scheme Screenshot -configuration Release \
            -destination 'generic/platform=iOS' \
            -archivePath "$RUNNER_TEMP/Screenshot.xcarchive" \
            APP_TEAM_ID="${{ steps.signing.outputs.team_id }}" \
            APP_PROFILE_SPECIFIER="${{ steps.signing.outputs.profile_name }}" \
            CURRENT_PROJECT_VERSION="${{ steps.version.outputs.build_number }}" \
            | tee "$RUNNER_TEMP/archive.log" | grep -E "error:|warning: .*[Ss]ign|ARCHIVE" || true
          grep -q "ARCHIVE SUCCEEDED" "$RUNNER_TEMP/archive.log" || { tail -100 "$RUNNER_TEMP/archive.log"; exit 1; }

      - name: Export IPA
        if: steps.secrets.outputs.can_sign == 'true'
        run: |
          set -euo pipefail
          cat > "$RUNNER_TEMP/ExportOptions.plist" <<PLIST
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>method</key><string>app-store-connect</string>
            <key>destination</key><string>export</string>
            <key>signingStyle</key><string>manual</string>
            <key>teamID</key><string>${{ steps.signing.outputs.team_id }}</string>
            <key>signingCertificate</key><string>Apple Distribution</string>
            <key>provisioningProfiles</key>
            <dict>
              <key>${{ steps.signing.outputs.bundle_id }}</key><string>${{ steps.signing.outputs.profile_name }}</string>
            </dict>
            <key>uploadSymbols</key><true/>
            <key>manageAppVersionAndBuildNumber</key><false/>
          </dict>
          </plist>
          PLIST
          xcodebuild -exportArchive \
            -archivePath "$RUNNER_TEMP/Screenshot.xcarchive" \
            -exportOptionsPlist "$RUNNER_TEMP/ExportOptions.plist" \
            -exportPath "$RUNNER_TEMP/export"
          ls -la "$RUNNER_TEMP/export"

      - name: Upload to TestFlight
        if: steps.secrets.outputs.can_sign == 'true'
        run: |
          set -euo pipefail
          IPA=$(find "$RUNNER_TEMP/export" -name '*.ipa' | head -1)
          xcrun altool --upload-app --type ios --file "$IPA" \
            --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
          echo "### Uploaded build ${{ steps.version.outputs.build_number }} to TestFlight" >> "$GITHUB_STEP_SUMMARY"
          echo "Processing by Apple usually takes 5–30 minutes before the build appears in TestFlight." >> "$GITHUB_STEP_SUMMARY"

      - name: Keep the IPA
        if: steps.secrets.outputs.can_sign == 'true'
        uses: actions/upload-artifact@v4
        with:
          name: Screenshot-${{ steps.version.outputs.build_number }}
          path: ${{ runner.temp }}/export/*.ipa
          retention-days: 14

      - name: Clean up secrets
        if: always()
        run: |
          security delete-keychain "$RUNNER_TEMP/signing.keychain-db" 2>/dev/null || true
          rm -f "$RUNNER_TEMP/dist.p12" "$RUNNER_TEMP/profile.mobileprovision" "$RUNNER_TEMP/profile.plist"
          rm -rf "$HOME/.appstoreconnect"
```
