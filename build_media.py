#!/usr/bin/env python3
"""
Builds per-brand, per-CAMPAIGN media collections for the portfolio.

  python3 build_media.py images   -> optimize all images (sips), write assets/media-data.js
                                     (videos are predicted; run the video step to create them)

Image sources: ~/Desktop/portfolio-images/<brand>/<campaign>/...  (loose files -> "More")
Video sources: ~/Desktop/portfolio-videos/<brand>/...             (flat -> "Reels & Films")

Each brand's existing cover.jpg is preserved.
"""
import os, sys, subprocess, json, re

ROOT      = "/Users/macsutherland/Desktop/mac-sutherland-portfolio"
IMG_SRC   = "/Users/macsutherland/Desktop/portfolio-images"
VID_SRC   = "/Users/macsutherland/Desktop/portfolio-videos"
IMG_OUT   = os.path.join(ROOT, "assets/img")
VID_OUT   = os.path.join(ROOT, "assets/video")
MAXDIM, QUALITY = 1600, 72

# slug, brand name, images-folder, videos-folder ('' = none)
BRANDS = [
    ("north-kiteboarding", "North Kiteboarding", "North_kiteboarding_images", "North_kiteboarding_videos"),
    ("north-foils",        "North Foils",        "North_foils_images",        "North_folis_videos"),
    ("surf-life-saving-nz","Surf Life Saving NZ","surf_life_saving_images",    "Surf_life_saving_videos"),
    ("surfr-app",          "The Surfr App",      "the_surfr_app_images",       "the_surfr_app_videos"),
    ("bike-storage",       "The Bike Storage Company", "Bike_storage_company_images", ""),
]

# nice human labels for messy folder names
LABELS = {
    "go_north_rebrand_campaign_2023": "Go North Rebrand 2023",
    "surf_collection_2024": "Surf Collection 2024",
    "big_air_2024": "Big Air 2024",
    "code_zero_kite_product_launch": "Code Zero Product Launch",
    "Iceland_Mystic_Campaign": "Iceland Mystic Campaign",
    "Jesse_Norton_Carve_Kite": "Jesse Richman carving legendary big-wave surf break Pe'ahi, Maui",
    "2026_surf_life_saving_championships": "2026 Surf Life Saving Championships",
    "bp_irb_championships_2026": "BP IRB Championships 2026",
    "international_surf_rescue_challenege_2025": "International Surf Rescue Challenge 2025",
    "Cold_Hawaii_Event": "Cold Hawaii Event",
    "Surfie_Update_Launch": "Surfie Update Launch",
    "Surfr_App_Leaderboards": "App Leaderboards",
    "Surfr_King_of_the_air_rider_cards": "King of the Air Rider Cards",
    "Monthly_Leaderboard_redesign": "Monthly Leaderboard Redesign",
    "IG_Stories": "IG Stories",
}
def label_for(folder):
    return LABELS.get(folder, re.sub(r"[_\-]+", " ", folder).strip().title())

def cslug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")

IMG_EXTS = (".jpg", ".jpeg", ".png")
def list_imgs(d):
    if not os.path.isdir(d): return []
    return sorted(f for f in os.listdir(d)
                  if f.lower().endswith(IMG_EXTS) and not f.startswith("."))
def list_vids(d):
    if not os.path.isdir(d): return []
    return sorted(f for f in os.listdir(d)
                  if f.lower().endswith((".mp4", ".mov")) and not f.startswith("."))

def sips(src, dst):
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", str(QUALITY),
                    "-Z", str(MAXDIM), src, "--out", dst],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)

def build_images():
    media = {}
    for slug, name, ifolder, vfolder in BRANDS:
        src_brand = os.path.join(IMG_SRC, ifolder)
        out_brand = os.path.join(IMG_OUT, slug)
        os.makedirs(out_brand, exist_ok=True)
        # wipe old generated collection dirs + flat numbered files, keep cover.jpg
        for entry in os.listdir(out_brand):
            p = os.path.join(out_brand, entry)
            if entry == "cover.jpg": continue
            if os.path.isdir(p):
                for f in os.listdir(p): os.remove(os.path.join(p, f))
                os.rmdir(p)
            elif re.match(r"\d+\.jpg", entry):
                os.remove(p)

        # discover collections: subdirs (campaigns) + loose ("More")
        subdirs = sorted(d for d in os.listdir(src_brand)
                         if os.path.isdir(os.path.join(src_brand, d)) and not d.startswith("."))
        collections = []
        for d in subdirs:
            collections.append((label_for(d), list_imgs(os.path.join(src_brand, d)),
                                os.path.join(src_brand, d)))
        loose = list_imgs(src_brand)
        if loose:
            lbl = "More" if subdirs else f"{name}"   # flat brand -> grouped under company
            collections.append((lbl, loose, src_brand))

        # optimize + record
        brand_cols = []
        first_img = None
        # order: keep campaign subdirs first (as discovered), loose last
        for cl, files, srcdir in collections:
            if not files: continue
            cs = cslug(cl) or "work"
            outdir = os.path.join(out_brand, cs); os.makedirs(outdir, exist_ok=True)
            imgs = []
            for i, f in enumerate(files, 1):
                dst = os.path.join(outdir, f"{i:03d}.jpg")
                sips(os.path.join(srcdir, f), dst)
                rel = f"assets/img/{slug}/{cs}/{i:03d}.jpg"
                imgs.append(rel)
                if first_img is None: first_img = os.path.join(outdir, f"{i:03d}.jpg")
            brand_cols.append({"label": cl, "slug": cs, "images": imgs, "videos": []})

        # videos -> single "Reels & Films" collection (flat sources, grouped under company)
        if vfolder:
            vids = list_vids(os.path.join(VID_SRC, vfolder))
            if vids:
                vlist = [{"src": f"assets/video/{slug}/reels/{i:03d}.mp4",
                          "poster": f"assets/video/{slug}/reels/{i:03d}.jpg"}
                         for i in range(1, len(vids) + 1)]
                brand_cols.append({"label": "Reels & Films", "slug": "reels",
                                   "images": [], "videos": vlist})

        # cover: keep existing, else first optimized image
        cover_path = os.path.join(out_brand, "cover.jpg")
        if not os.path.exists(cover_path) and first_img:
            sips(first_img, cover_path)

        media[slug] = {"name": name, "cover": f"assets/img/{slug}/cover.jpg",
                       "collections": brand_cols}
        print(f"{slug}: " + ", ".join(f"{c['label']}[{len(c['images']) or len(c['videos'])}]"
                                      for c in brand_cols))

    data = os.path.join(ROOT, "assets/media-data.js")
    with open(data, "w") as f:
        f.write("// Auto-generated by build_media.py - do not edit by hand.\n")
        f.write("window.MEDIA = " + json.dumps(media, indent=1) + ";\n")
    print("Wrote", data)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "images":
        build_images()
    else:
        print("usage: build_media.py images")
