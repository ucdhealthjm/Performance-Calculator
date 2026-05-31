#!/usr/bin/env python3
"""Generate the Open Graph / Twitter Card hero image for the calculator.

Run from the repo root:
    python3 generate_og_image.py

Writes og-image.png (1200x630, the size Twitter/X, LinkedIn, and Facebook prefer).
Re-run this if the headline copy ever changes.
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import sys

W, H = 1200, 630
NAVY = (0, 51, 102)
BLUE = (0, 86, 179)
WARN_BG = (255, 251, 230)
WARN_FG = (102, 77, 3)
WHITE = (255, 255, 255)
GREY = (108, 117, 125)

def find_font(*names, size=40):
    candidates = []
    for name in names:
        candidates += [
            f"/System/Library/Fonts/{name}",
            f"/Library/Fonts/{name}",
            f"/System/Library/Fonts/Supplemental/{name}",
        ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()

img = Image.new("RGB", (W, H), WHITE)
draw = ImageDraw.Draw(img)

# Navy header bar
draw.rectangle([(0, 0), (W, 130)], fill=NAVY)

f_title  = find_font("HelveticaNeue.ttc", "Helvetica.ttc", "Arial.ttf", size=44)
f_kicker = find_font("HelveticaNeue.ttc", "Helvetica.ttc", "Arial.ttf", size=22)
f_huge   = find_font("HelveticaNeueBold.ttc", "Helvetica.ttc", "Arial Bold.ttf", size=130)
f_med    = find_font("HelveticaNeue.ttc", "Helvetica.ttc", "Arial.ttf", size=34)
f_small  = find_font("HelveticaNeue.ttc", "Helvetica.ttc", "Arial.ttf", size=24)
f_cite   = find_font("HelveticaNeue.ttc", "Helvetica.ttc", "Arial.ttf", size=20)

draw.text((50, 35),  "Medical Performance Sleep Calculator", fill=WHITE, font=f_title)
draw.text((50, 88),  "An interactive companion to a published Monte Carlo simulation",
          fill=(220, 230, 245), font=f_kicker)

# Headline result card: illustrates the model at a clinically meaningful state
draw.text((50, 165), "At 4 hours of sleep, predicted performance is",
          fill=GREY, font=f_med)

# Use textbbox to position the unit label flush to the right edge of "424 ms"
big = "424 ms"
draw.text((50, 215), big, fill=BLUE, font=f_huge)
bbox = draw.textbbox((50, 215), big, font=f_huge)
draw.text((bbox[2] + 18, bbox[3] - 48), "reaction time", fill=GREY, font=f_med)

draw.text((50, 380), "~70% higher medical-error risk vs. rested",
          fill=NAVY, font=f_med)

# BAC equivalence in a warning band
band_y0 = 445
band_y1 = 525
draw.rectangle([(50, band_y0), (W - 50, band_y1)], fill=WARN_BG, outline=(255, 229, 143), width=2)
draw.text((70, band_y0 + 22),
          "Equivalent to a blood alcohol concentration of ~0.05%",
          fill=WARN_FG, font=f_med)

# Footer citation
draw.text((50, H - 60),
          "Moen J. Cureus 17(10): e95729 (2025). doi:10.7759/cureus.95729",
          fill=GREY, font=f_cite)
draw.text((50, H - 32),
          "ucdhealthjm.github.io/Performance-Calculator",
          fill=NAVY, font=f_cite)

out = Path(__file__).parent / "og-image.png"
img.save(out, "PNG", optimize=True)
print(f"Wrote {out} ({out.stat().st_size // 1024} KB)")
