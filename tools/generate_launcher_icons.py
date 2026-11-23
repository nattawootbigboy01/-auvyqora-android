#!/usr/bin/env python3
"""Render the branded SVG launcher icon into Android density buckets."""
import argparse
import re
from pathlib import Path
import cairosvg
from PIL import Image
from io import BytesIO

parser = argparse.ArgumentParser()
parser.add_argument("--project-dir", required=True)
parser.add_argument("--icon", required=True)
parser.add_argument("--label", required=True)
args = parser.parse_args()

project = Path(args.project_dir)
svg = Path(args.icon).read_bytes()
png = cairosvg.svg2png(bytestring=svg, output_width=512, output_height=512)
source = Image.open(BytesIO(png)).convert("RGBA")
res = project / "android/app/src/main/res"
for density, size in {"mdpi":48,"hdpi":72,"xhdpi":96,"xxhdpi":144,"xxxhdpi":192}.items():
    folder = res / f"mipmap-{density}"
    folder.mkdir(parents=True, exist_ok=True)
    source.resize((size,size), Image.Resampling.LANCZOS).save(folder / "ic_launcher.png", optimize=True)
    source.resize((size,size), Image.Resampling.LANCZOS).save(folder / "ic_launcher_round.png", optimize=True)

manifest = project / "android/app/src/main/AndroidManifest.xml"
content = manifest.read_text()
content, count = re.subn(r'android:label="[^"]+"', f'android:label="{args.label}"', content, count=1)
if count != 1:
    raise SystemExit("Could not find Android app label in generated manifest")
manifest.write_text(content)
print(f"Installed {args.label} launcher artwork and uppercase app label.")
