#!/bin/zsh
# Records the raw screen footage for the App Store app preview.
#
# Builds first, so the recording holds only the walk through the app
# (AppStoreScreenshots.testWalkForAppPreview), then saves it as an .mov.
# Use a simulator that isn't running other tests: recording can wedge testmanagerd.
#
# Usage: tools/app-preview.sh <simulator-udid> <output.mov> [derived-data-path]

set -euo pipefail

udid=${1:?Pass a simulator UDID}
out=${2:?Pass an output .mov path}
derived=${3:-$(mktemp -d)}
project="$(cd "$(dirname "$0")/.." && pwd)/NicFree/NicFree.xcodeproj"
mkdir -p "$derived" "$(dirname "$out")"

xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b > /dev/null
xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiBars 3 --dataNetwork wifi

common=(-project "$project" -scheme "NicFree Debug" -destination "id=$udid" -derivedDataPath "$derived")
xcodebuild build-for-testing "${common[@]}" > "$derived/preview-build.log" 2>&1 \
    || { echo "BUILD FAILED: see $derived/preview-build.log"; exit 1; }

rm -f "$out"
xcrun simctl io "$udid" recordVideo --codec=h264 --force "$out" > /dev/null 2>&1 &
recorder=$!
sleep 2

TEST_RUNNER_SCREENSHOTS=1 TEST_RUNNER_PREVIEW=1 xcodebuild test-without-building "${common[@]}" \
    -only-testing:NicFreeUITests/AppStoreScreenshots/testWalkForAppPreview \
    > "$derived/preview-test.log" 2>&1 || rc=$?

kill -INT $recorder; wait $recorder 2>/dev/null || true
xcrun simctl status_bar "$udid" clear
[[ -z "${rc:-}" ]] || { echo "TEST FAILED: see $derived/preview-test.log"; exit 1; }
echo "$out"
