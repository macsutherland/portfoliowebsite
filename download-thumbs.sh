#!/bin/bash
# Download the real Instagram post thumbnails (og:image) for the carousel, store locally
# (CDN URLs are signed/expire, so we save + optimize copies). Output: assets/img/posts/<shortcode>.jpg
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
OUT="/Users/macsutherland/Desktop/mac-sutherland-portfolio/assets/img/posts"
mkdir -p "$OUT"

SHORTCODES=(DWaovM5jwjR CnmzDAAJv5E CoHMHZPux4q CuBtjRRv6zT CoJ1EFMO_ps CuH7gwUJYt0 DVfkHqOj6Wu CsLYR0EP8Wh Cu_m9iHvH3e CnRHXllpE1P Cw4X7q6vJtG DVnbLbJj30t DVpx8BGDzKN Cs3JAinPeeD DVmsyIjDw4h DZ9TINUmxen DZuEFmlDgAE)

ok=0; fail=0
for sc in "${SHORTCODES[@]}"; do
  img=$(curl -fsSL -A "$UA" "https://www.instagram.com/p/$sc/" 2>/dev/null \
        | grep -o '<meta property="og:image" content="[^"]*"' | head -1 \
        | sed 's/.*content="//; s/"$//; s/&amp;/\&/g')
  if [ -n "$img" ] && curl -fsSL -A "$UA" -o "$OUT/$sc.src" "$img" 2>/dev/null; then
    sips -s format jpeg -s formatOptions 78 -Z 900 "$OUT/$sc.src" --out "$OUT/$sc.jpg" >/dev/null 2>&1 \
      && rm -f "$OUT/$sc.src" && echo "ok   $sc" && ok=$((ok+1)) \
      || { echo "BAD-IMG $sc"; fail=$((fail+1)); }
  else
    echo "FAIL $sc (no og:image)"; fail=$((fail+1))
  fi
  sleep 2
done
echo "----- downloaded: $ok, failed: $fail -----"
ls -la "$OUT"/*.jpg 2>/dev/null | wc -l