#!/bin/bash
# Transcode ALL brand videos -> assets/video/<slug>/reels/NNN.mp4 (+ NNN.jpg posters).
# Matches the "Reels & Films" collection paths predicted by build_media.py.
# H.264, CRF 28, long edge <= 960. Handles .mp4 + .mov. Ordering = LC_ALL=C (matches Python sorted()).
#
# Needs ffmpeg at /tmp/ffbin/ffmpeg (arm64). Get one:
#   curl -fsSL -o /tmp/ff.zip https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffmpeg.zip
#   unzip -o /tmp/ff.zip -d /tmp/ffbin && chmod +x /tmp/ffbin/ffmpeg
set -e
FF="/tmp/ffbin/ffmpeg"
VID_SRC="/Users/macsutherland/Desktop/portfolio-videos"
VID_OUT="/Users/macsutherland/Desktop/mac-sutherland-portfolio/assets/video"

# slug | videos-folder
BRANDS=(
"north-kiteboarding|North_kiteboarding_videos"
"north-foils|North_folis_videos"
"surf-life-saving-nz|Surf_life_saving_videos"
"surfr-app|the_surfr_app_videos"
)

for entry in "${BRANDS[@]}"; do
  IFS='|' read -r slug vfolder <<< "$entry"
  src="$VID_SRC/$vfolder"; out="$VID_OUT/$slug/reels"
  mkdir -p "$out"; rm -f "$out"/*.mp4 "$out"/*.jpg
  echo "→ $slug"
  n=0
  while IFS= read -r f; do
    n=$((n+1)); printf -v num "%03d" "$n"
    "$FF" -nostdin -y -loglevel error -i "$src/$f" \
      -vf "scale=w='if(gt(iw,ih),960,-2)':h='if(gt(iw,ih),-2,960)'" \
      -c:v libx264 -crf 28 -preset veryfast -pix_fmt yuv420p \
      -c:a aac -b:a 96k -movflags +faststart "$out/$num.mp4"
    qlmanage -t -s 1000 -o "$out" "$src/$f" >/dev/null 2>&1 || true
    png=$(ls "$out"/*.png 2>/dev/null | head -1)
    [ -n "$png" ] && sips -s format jpeg -s formatOptions 72 "$png" --out "$out/$num.jpg" >/dev/null 2>&1 && rm -f "$png"
    echo "   $slug $num done ($(du -h "$out/$num.mp4"|cut -f1)) <- $f"
  done < <(cd "$src" && LC_ALL=C ls | grep -iE '\.(mp4|mov)$')
done
echo "VIDEO BUILD COMPLETE"; du -sh "$VID_OUT"
