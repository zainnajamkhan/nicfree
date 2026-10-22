#!/bin/zsh
# Captures the App Store screenshots on one simulator and saves them as PNGs.
#
# Usage: tools/screenshots.sh <simulator-udid> <output-folder> [derived-data-path]
# Use an iPhone 17 Pro Max for the 6.9" set and an iPad Pro 13-inch for the iPad set.

set -euo pipefail

udid=${1:?Pass a simulator UDID}
out=${2:?Pass an output folder}
derived=${3:-$(mktemp -d)}
project="$(cd "$(dirname "$0")/.." && pwd)/NicFree/NicFree.xcodeproj"
bundle="$derived/screenshots.xcresult"
mkdir -p "$out" "$derived"
rm -rf "$bundle"

# A clean status bar: 9:41, full battery, full signal.
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b > /dev/null
xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiBars 3 --dataNetwork wifi

TEST_RUNNER_SCREENSHOTS=1 xcodebuild test -project "$project" -scheme NicFree \
    -destination "id=$udid" -derivedDataPath "$derived" -parallel-testing-enabled NO \
    -test-timeouts-enabled YES -maximum-test-execution-time-allowance 420 \
    -only-testing:NicFreeUITests/AppStoreScreenshots -resultBundlePath "$bundle" \
    > "$derived/screenshots.log" 2>&1 || { echo "FAILED: see $derived/screenshots.log"; exit 1; }

xcrun simctl status_bar "$udid" clear

export_dir="$derived/attachments"
rm -rf "$export_dir"
xcrun xcresulttool export attachments --path "$bundle" --output-path "$export_dir" > /dev/null
python3 - "$export_dir" "$out" <<'EOF'
import json, shutil, sys
src, dst = sys.argv[1], sys.argv[2]
for test in json.load(open(f"{src}/manifest.json")):
    for a in test.get("attachments", []):
        name = a.get("suggestedHumanReadableName", "").split("_0_")[0]
        if a["exportedFileName"].endswith(".png") and name[:2].isdigit():
            shutil.copy(f"{src}/{a['exportedFileName']}", f"{dst}/{name}.png")
            print(f"{dst}/{name}.png")
EOF
