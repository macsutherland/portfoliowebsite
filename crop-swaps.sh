#!/bin/bash
# Crop the carousel-swap images to uniform 4:5 and overwrite the matching post thumbnails.
set -e
FF="/tmp/ffbin/ffmpeg"
SRC="/Users/macsutherland/Desktop/carousel-swaps"
OUT="/Users/macsutherland/Desktop/mac-sutherland-portfolio/assets/img/posts"

# src-file | shortcode | vertical-bias (0.5 = centre, lower = keep more of the top)
JOBS=(
"camille_dellanoy_lighting_it_upg_mock_up.png|Cw4X7q6vJtG|0.5"
"day_02_bp_irb_ig_image_ig_mockup.png|DWaovM5jwjR|0.42"
"mega_loop_10m_orbit.png|CsLYR0EP8Wh|0.5"
"thats_a_wrap_aon_champs_image_ig_mockup.png|DVnbLbJj30t|0.28"
)

for job in "${JOBS[@]}"; do
  IFS='|' read -r file sc bias <<< "$job"
  read w h < <(sips -g pixelWidth -g pixelHeight "$SRC/$file" | awk '/pixelWidth/{w=$2}/pixelHeight/{h=$2}END{print w,h}')
  read cw ch yo < <(python3 -c "
w,h=$w,$h; bias=$bias
cw=w; ch=round(w*1.25)         # 4:5
if ch>h: ch=h; cw=round(h*0.8) # safety if source were wider than 4:5
yo=round((h-ch)*bias)
print(cw, ch, yo)")
  "$FF" -nostdin -y -loglevel error -i "$SRC/$file" \
    -vf "crop=${cw}:${ch}:0:${yo},scale=-2:1100" -q:v 3 "$OUT/$sc.jpg"
  echo "$sc <- $file  crop ${cw}x${ch} @y${yo}  -> $(sips -g pixelWidth -g pixelHeight "$OUT/$sc.jpg" | awk '/pixelWidth/{w=$2}/pixelHeight/{h=$2}END{print w"x"h}')"
done