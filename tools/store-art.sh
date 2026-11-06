#!/bin/zsh
# Renders the sprout stages and share cards to PNGs, for the App Store artwork.
#
# Usage: tools/store-art.sh <simulator-udid> <output-folder> [derived-data-path]

set -euo pipefail
udid=${1:?Pass a simulator UDID}
out=${2:?Pass an output folder}
derived=${3:-$(mktemp -d)}
mkdir -p "$out" "$derived"
out=$(cd "$out" && pwd)
project="$(cd "$(dirname "$0")/.." && pwd)/NicFree/NicFree.xcodeproj"

TEST_RUNNER_ART_DIR="$out" xcodebuild test -project "$project" -scheme "NicFree Debug" \
    -destination "id=$udid" -derivedDataPath "$derived" \
    -only-testing:NicFreeTests/StoreArtExport > "$derived/store-art.log" 2>&1 \
    || { echo "FAILED: see $derived/store-art.log"; exit 1; }
ls "$out"
