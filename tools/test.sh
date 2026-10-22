#!/bin/zsh
# Runs every NicFree test: unit tests first, then UI tests, as two separate passes.
#
# They are kept apart on purpose. The UI tests open the paywall through the scheme's
# StoreKit configuration, and that state on the simulator stops the purchase unit test's
# own StoreKit test session from loading the product when both share one run.
#
# Usage: tools/test.sh <simulator-udid> [derived-data-path]

set -euo pipefail

udid=${1:?Pass a simulator UDID (xcrun simctl list devices)}
derived=${2:-$(mktemp -d)}
mkdir -p "$derived"
project="$(cd "$(dirname "$0")/.." && pwd)/NicFree/NicFree.xcodeproj"

run() {
    local name=$1; shift
    local bundle="$derived/$name.xcresult"
    rm -rf "$bundle"
    if xcodebuild test -project "$project" -scheme NicFree -destination "id=$udid" \
        -derivedDataPath "$derived" -parallel-testing-enabled NO \
        -test-timeouts-enabled YES -maximum-test-execution-time-allowance 420 \
        -resultBundlePath "$bundle" "$@" > "$derived/$name.log" 2>&1; then
        echo "$name: passed"
    else
        echo "$name: FAILED (see $derived/$name.log and $bundle)"
        return 1
    fi
}

run unit -only-testing:NicFreeTests
run ui -only-testing:NicFreeUITests
