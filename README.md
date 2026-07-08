# Mac Sutherland — Portfolio

Dark, gallery-style single-page portfolio for a digital marketing & social media manager working in water / action-sports. No build step, no dependencies — just open it.

## Run it
Open `index.html` in a browser, or serve the folder:
```bash
ruby server.rb                # then visit http://localhost:8000
# or: python3 -m http.server 8000
```

## Media (images + video), grouped by campaign
Each brand's work is split into **collections** (campaigns / events / launches). Where the source
folders have campaign subfolders, those become labelled sub-galleries; flat folders are grouped
under the company. Every collection is lazy-loaded with a click-to-open **lightbox** scoped to that
collection (prev/next, keyboard arrows, inline video playback).

- **Images:** `assets/img/<slug>/cover.jpg` + `assets/img/<slug>/<campaign>/NNN.jpg`
- **Videos:** `assets/video/<slug>/reels/NNN.mp4` (H.264, long edge ≤ 960) + `NNN.jpg` posters
- **Manifest:** `assets/media-data.js` sets `window.MEDIA` —
  `{ slug: { name, cover, collections:[{ label, slug, images[], videos[{src,poster}] }] } }`.
  Loaded before `script.js`, so galleries work even over `file://`.

### Rebuilding media
```bash
python3 build_media.py images     # optimize ALL images (sips), regenerate media-data.js
bash build-videos-ffmpeg.sh       # transcode ALL videos (ffmpeg CRF 28) into <slug>/reels/ + posters
```
`build_media.py` reads `~/Desktop/portfolio-images`, the video script reads `~/Desktop/portfolio-videos`.
Brand→folder mapping and the campaign **label overrides** are at the top of `build_media.py`.

**ffmpeg note:** there's no system ffmpeg and macOS `avconvert` bloats files ~2×. Use an **arm64**
static build (the evermeet.cx one is Intel-only → "Bad CPU type" on Apple Silicon):
```bash
curl -fsSL -o /tmp/ff.zip https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffmpeg.zip
unzip -o /tmp/ff.zip -d /tmp/ffbin && chmod +x /tmp/ffbin/ffmpeg
```

> Note: `the_surfr_app_images/IG_Stories/` holds only a multi-page **PDF**, which isn't rasterized
> (no poppler here), so that collection is skipped. Export it to PNGs and re-run to include it.

## Files
| File | Purpose |
|------|---------|
| `index.html` | Page structure & section content |
| `styles.css` | Color/type system + all styling (theme tokens live in `:root`) |
| `script.js`  | Renders the work grid, services, content samples, and runs the case-study modal, nav, reveals, form |

## Editing your content
Almost everything is data-driven in **`script.js`** — edit the arrays at the top:
- `CASES` — the five brand case studies (slug, tag, name, role, metrics, challenge, what-you-did). The `slug` maps to the `assets/img/<slug>/` folder. **Metrics are placeholders — swap in your real numbers.**
- `SERVICES` — the services grid.
- `SAMPLES` — the content-sample cards (platform, format, handle, likes).

The masonry grid and each case study's gallery are built automatically from the images in each brand's folder. Colors live in `styles.css` under `:root` (the `--surf / --depth / --sunline` "elements").

## A couple of things to personalize
- **About portrait** (`index.html`, `.about__photo`) currently reuses a North Foils shot — swap `src` for an actual photo of you.
- **Metrics** in `CASES` are realistic placeholders — replace with your true results.
- **Social links** in the `#contact` section.

## Make the contact form work
The form is a demo (no backend). Easiest options:
- **Netlify Forms** — add `netlify` to the `<form>` tag and deploy on Netlify.
- **Formspree** — set the form `action` to your Formspree endpoint and `method="POST"`.

## Deploy
Drop the folder on **Netlify**, **Vercel**, or **GitHub Pages** — it's fully static.

## To personalize quickly
- Name/brand: search `Mac Sutherland` in `index.html`.
- Hero headline & positioning: top of `index.html` (`.hero`).
- Social links & email: `#contact` section in `index.html`.
- Stats strip numbers: `.stats` section in `index.html`.
