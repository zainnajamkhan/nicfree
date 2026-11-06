#!/bin/zsh
# Renders the App Store screenshots and the product page art from screenshots/source.
#
# Before running: tools/screenshots.sh for the raw captures (copied into source/cap as
# iphone-*.png and ipad-*.png) and tools/store-art.sh for source/art.
#
# Usage: tools/store-frames.sh

set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)/screenshots"
src="$root/source"
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

shoot() { # url width height out
    "$chrome" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
        --force-device-scale-factor=1 --window-size="$2,$3" --screenshot="$4" "$1" 2>/dev/null
    sips -z "$3" "$2" "$4" > /dev/null   # exact pixels, whatever the window chrome did
}

mkdir -p "$root/iphone-6.9" "$root/iphone-6.3" "$root/ipad-13" "$root/header"
for f in 1 2 3 4 5 6; do
    shoot "file://$src/frames.html?f=$f" 1320 2868 "$root/iphone-6.9/0$f.png"
    cp "$root/iphone-6.9/0$f.png" "$root/iphone-6.3/0$f.png"
    sips -z 2622 1206 "$root/iphone-6.3/0$f.png" > /dev/null
    shoot "file://$src/frames.html?f=$f&d=ipad" 2064 2752 "$root/ipad-13/0$f.png"
done

shoot "file://$src/header.html?w=3840&h=1646&s=560&cy=0.52" 3840 1646 "$root/header/header-3840x1646.png"
shoot "file://$src/header.html?w=3840&h=2560&s=740&cy=0.5" 3840 2560 "$root/header/search-3840x2560.png"
shoot "file://$src/header.html?w=5244&h=2950&s=860&cy=0.5" 5244 2950 "$root/header/universal-5244x2950.png"
ls "$root"/iphone-6.9 "$root"/ipad-13 "$root"/header
