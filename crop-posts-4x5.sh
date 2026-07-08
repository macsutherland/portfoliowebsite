#!/bin/bash
# Crop the carousel post thumbnails to a uniform 4:5 (centered, no distortion).
# Keeps full width on verticals, centre-crops sides on squares.
DIR="/Users/macsutherland/Desktop/mac-sutherland-portfolio/assets/img/posts"
for f in "$DIR"/*.jpg; do
  read w h < <(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixelWidth/{w=$2}/pixelHeight/{h=$2}END{print w, h}')
  # target ratio 4:5 => w/h = 0.8
  read nw nh < <(python3 -c "
w,h=$w,$h
if w/h > 0.8:        # too wide -> trim sides
    nw=round(h*0.8); nh=h
else:                # too tall -> trim top/bottom
    nw=w; nh=round(w/0.8)
print(nw, nh)")
  sips -c "$nh" "$nw" "$f" --out "$f" >/dev/null 2>&1   # sips -c is height then width
  echo "$(basename "$f"): ${w}x${h} -> ${nw}x${nh}"
done