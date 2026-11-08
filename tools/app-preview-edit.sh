#!/bin/zsh
# Edits the raw footage from tools/app-preview.sh into two videos:
#   app-preview-iphone.mp4  886 x 1920, ~16 s, full-screen footage with captions, for the
#                           App Store (previews must be 15 to 30 s of the app itself)
#   teaser-6s.mp4           1080 x 1920, ~6 s, phone on a backdrop, for the site and anywhere else
#
# Cut points are seconds into the raw recording of AppStoreScreenshots.testWalkForAppPreview.
# Needs ffmpeg (a local tool only; nothing ships in the app) and Google Chrome.
#
# Usage: tools/app-preview-edit.sh <raw.mov> [output-folder]

set -euo pipefail
raw=${1:?Pass the raw .mov}
root="$(cd "$(dirname "$0")/.." && pwd)/screenshots"
out=${2:-$root/preview}
src="$root/source"
work="$(mktemp -d)"
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p "$out"

still() { # query width height out
    "$chrome" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files \
        --default-background-color=00000000 --force-device-scale-factor=1 \
        --window-size="$2,$3" --screenshot="$4" "file://$src/preview.html?$1" 2>/dev/null
    sips -z "$3" "$2" "$4" > /dev/null
}

for c in green sky clay; do still "m=bg&c=$c" 1080 1920 "$work/bg-$c.png"; done
still "m=cap&c=green&a=Quit%20Zyn%20%26&b=nicotine%20pouches." 1080 520 "$work/cap1.png"
still "m=cap&c=sky&a=Ride%20out&b=the%20craving." 1080 520 "$work/cap2.png"
still "m=cap&c=green&a=Slipped%3F&b=Free%20days%20stay." 1080 520 "$work/cap3.png"
still "m=end" 1080 1920 "$work/end.png"
still "m=pill&t=Quit%20Zyn%20%26%3Cbr%3Enicotine%20pouches" 886 300 "$work/pill1.png"
still "m=pill&t=Every%20free%20day%3Cbr%3Ecounts.%20Forever." 886 300 "$work/pill2.png"
still "m=pill&t=Ride%20out%3Cbr%3Ethe%20craving" 886 300 "$work/pill3.png"
still "m=pill&t=Slipped%3F%3Cbr%3EFree%20days%20stay." 886 300 "$work/pill4.png"

# ---- 6 second teaser -------------------------------------------------------------------
# scene: start end speed backdrop caption seconds-out
scene() {
    local s=$1 e=$2 sp=$3 bg=$4 cap=$5 o=$6
    local d=$(( (e - s) / sp ))
    ffmpeg -v error -y -i "$raw" -loop 1 -t $d -i "$work/bg-$bg.png" -loop 1 -t $d -i "$work/$cap.png" \
        -f lavfi -t $d -i "color=c=white:s=1080x1920:r=30" -filter_complex "
        [0:v]trim=$s:$e,setpts=(PTS-STARTPTS)/$sp,fps=30,scale=720:1564[v];
        [3:v][v]overlay=180:600:shortest=1[b1];
        [b1][1:v]overlay=0:0[b2];
        [2:v]format=rgba,fade=in:st=0.1:d=0.35:alpha=1[c];
        [b2][c]overlay=x=0:y='60+50*max(0,1-(t-0.1)/0.35)'[b3];
        [b3]scale=2160:3840,zoompan=z='1+0.04*on/($d*30)':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1080x1920:fps=30,format=yuv420p[out]" \
        -map "[out]" -t $d -c:v libx264 -crf 16 -preset slow "$o"
}
scene 8.2 10.6 1.25 green cap1 "$work/s1.mp4"
scene 20.0 23.6 2.0 sky cap2 "$work/s2.mp4"
scene 35.4 38.6 1.5 clay cap3 "$work/s3.mp4"
ffmpeg -v error -y -loop 1 -t 1.3 -i "$work/end.png" -vf "scale=2160:3840,zoompan=z='1.04-0.04*on/39':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1080x1920:fps=30,format=yuv420p" \
    -c:v libx264 -crf 16 -preset slow "$work/s4.mp4"

dur() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"; }
t=0.3
o1=$(( $(dur "$work/s1.mp4") - t ))
o2=$(( o1 + $(dur "$work/s2.mp4") - t ))
o3=$(( o2 + $(dur "$work/s3.mp4") - t ))
ffmpeg -v error -y -i "$work/s1.mp4" -i "$work/s2.mp4" -i "$work/s3.mp4" -i "$work/s4.mp4" -filter_complex "
    [0:v][1:v]xfade=transition=smoothleft:duration=${t}:offset=${o1}[a];
    [a][2:v]xfade=transition=smoothleft:duration=${t}:offset=${o2}[b];
    [b][3:v]xfade=transition=fade:duration=${t}:offset=${o3},format=yuv420p[v]" \
    -map "[v]" -c:v libx264 -crf 17 -preset slow -movflags +faststart "$out/teaser-6s.mp4"

# ---- App Store preview, 886 x 1920 -----------------------------------------------------
seg() { # start end speed pill out
    local s=$1 e=$2 sp=$3 p=$4 o=$5
    local d=$(( (e - s) / sp ))
    ffmpeg -v error -y -i "$raw" -loop 1 -t $d -i "$work/$p.png" -filter_complex "
        [0:v]trim=$s:$e,setpts=(PTS-STARTPTS)/$sp,fps=30,scale=886:1925,crop=886:1920:0:0[v];
        [1:v]format=rgba,fade=in:st=0.15:d=0.3:alpha=1[c];
        [v][c]overlay=x=0:y='150+30*max(0,1-(t-0.15)/0.3)',format=yuv420p[out]" \
        -map "[out]" -t $d -c:v libx264 -crf 16 -preset slow "$o"
}
seg 8.2 12.0 1 pill1 "$work/p1.mp4"
seg 15.0 17.4 1 pill2 "$work/p2.mp4"
seg 19.0 28.0 1.5 pill3 "$work/p3.mp4"
seg 34.4 39.6 1 pill4 "$work/p4.mp4"
t=0.25
o1=$(( $(dur "$work/p1.mp4") - t ))
o2=$(( o1 + $(dur "$work/p2.mp4") - t ))
o3=$(( o2 + $(dur "$work/p3.mp4") - t ))
total=$(( o3 + $(dur "$work/p4.mp4") ))
# Apple wants a stereo audio track even when silent.
ffmpeg -v error -y -i "$work/p1.mp4" -i "$work/p2.mp4" -i "$work/p3.mp4" -i "$work/p4.mp4" \
    -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=48000" -filter_complex "
    [0:v][1:v]xfade=transition=fade:duration=${t}:offset=${o1}[a];
    [a][2:v]xfade=transition=fade:duration=${t}:offset=${o2}[b];
    [b][3:v]xfade=transition=fade:duration=${t}:offset=${o3},fps=30,format=yuv420p[v]" \
    -map "[v]" -map 4:a -t $total -c:v libx264 -profile:v high -crf 17 -preset slow \
    -c:a aac -b:a 256k -movflags +faststart "$out/app-preview-iphone.mp4"

for f in "$out"/*.mp4; do
    echo "$f $(ffprobe -v error -select_streams v -show_entries stream=width,height -of csv=p=0 "$f") $(dur "$f")s"
done
