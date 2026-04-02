#!/usr/bin/env python3
"""Generate all macOS app icon sizes from the 1024x1024 source."""

from PIL import Image
import os
import json

SOURCE = "/Users/jeandre/source/BliksemStudios/MacPathExplorer/docs/superpowers/design/icons/v2_a_folder_portal.png"
OUT_DIR = "/Users/jeandre/source/BliksemStudios/MacPathExplorer/NetPath/Resources/Assets.xcassets/AppIcon.appiconset"

SIZES = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

os.makedirs(OUT_DIR, exist_ok=True)
source = Image.open(SOURCE)

images_json = []
for point_size, scale in SIZES:
    pixel_size = point_size * scale
    filename = f"icon_{point_size}x{point_size}@{scale}x.png"

    resized = source.resize((pixel_size, pixel_size), Image.LANCZOS)
    resized.save(os.path.join(OUT_DIR, filename), "PNG")

    images_json.append({
        "filename": filename,
        "idiom": "mac",
        "scale": f"{scale}x",
        "size": f"{point_size}x{point_size}"
    })
    print(f"  {filename} ({pixel_size}x{pixel_size}px)")

contents = {
    "images": images_json,
    "info": {"author": "xcode", "version": 1}
}

with open(os.path.join(OUT_DIR, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print(f"\nDone — {len(SIZES)} sizes in {OUT_DIR}")
