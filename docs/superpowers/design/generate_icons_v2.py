#!/usr/bin/env python3
"""Generate 5 diverse NetPath app icon options — Voltaic Precision design language.
Each icon takes a fundamentally different conceptual approach."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

FONTS_DIR = "/Users/jeandre/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/833b45ed-3185-4a5e-9c94-932a74643858/de29a6d6-ab2b-4a5f-9127-0440efa28656/skills/canvas-design/canvas-fonts"
OUT_DIR = "/Users/jeandre/source/BliksemStudios/MacPathExplorer/docs/superpowers/design/icons"

SIZE = 1024
# Voltaic Precision palette
BLUE = (0, 102, 255)
BLUE_BRIGHT = (51, 153, 255)
BLUE_DIM = (0, 51, 153)
BLUE_DEEP = (0, 30, 90)
DARK_BG = (18, 18, 20)
DARKER = (12, 12, 14)
CHARCOAL = (28, 28, 32)
MID_GRAY = (55, 55, 60)
LIGHT_GRAY = (140, 140, 150)
WHITE = (235, 235, 240)
ACCENT_TEAL = (0, 180, 220)

def load_font(name, size):
    try:
        return ImageFont.truetype(os.path.join(FONTS_DIR, name), size)
    except:
        return ImageFont.load_default()

def rounded_rect_mask(size, radius):
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    return mask

def apply_mask(img, radius=180):
    mask = rounded_rect_mask(SIZE, radius)
    result = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    result.paste(img, mask=mask)
    return result

def gradient_bg(draw, color_top, color_bottom):
    """Draw a vertical gradient background."""
    for y in range(SIZE):
        t = y / SIZE
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * t)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * t)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * t)
        draw.line([(0, y), (SIZE, y)], fill=(r, g, b))


# ============================================================
# ICON A: "Folder Portal"
# A stylized folder shape with the \\ cut out as negative space,
# revealing a blue glowing interior. The folder is dark gray,
# the interior glows electric blue — suggests opening a path
# into a network share.
# ============================================================
def icon_a():
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)

    # Gradient background — very subtle
    gradient_bg(draw, (20, 20, 24), (14, 14, 16))

    # Folder body dimensions
    fx, fy = 160, 280
    fw, fh = 704, 520
    tab_w = 260
    tab_h = 70
    r = 32

    # Blue glow behind folder (the "portal" visible through the cutout)
    for gr in range(120, 0, -1):
        factor = (1 - gr/120) ** 2
        c = tuple(int(v * factor * 0.4) for v in BLUE)
        cx, cy = fx + fw//2, fy + fh//2 + 20
        draw.ellipse([cx - gr*3, cy - gr*2, cx + gr*3, cy + gr*2], fill=c)

    # Folder tab (top left portion)
    draw.rounded_rectangle(
        [fx, fy - tab_h, fx + tab_w, fy + r],
        radius=r, fill=CHARCOAL
    )
    # Folder body
    draw.rounded_rectangle(
        [fx, fy, fx + fw, fy + fh],
        radius=r, fill=CHARCOAL
    )

    # Cut out \\ as "window" into the folder — revealing blue glow
    slash_w = 44
    gap = 30

    # First backslash cutout
    s1x, s1y = fx + 200, fy + 80
    e1x, e1y = fx + 330, fy + fh - 80
    for w in range(slash_w + 20, 0, -1):
        if w > slash_w:
            # Glow edge
            factor = 1 - (w - slash_w) / 20
            c = tuple(int(v * factor * 0.6) for v in BLUE)
        else:
            c = BLUE
        draw.line([(s1x, s1y), (e1x, e1y)], fill=c, width=w)

    # Second backslash cutout
    s2x, s2y = s1x + slash_w + gap + 30, fy + 80
    e2x, e2y = s2x + 130, fy + fh - 80
    for w in range(slash_w + 20, 0, -1):
        if w > slash_w:
            factor = 1 - (w - slash_w) / 20
            c = tuple(int(v * factor * 0.6) for v in BLUE)
        else:
            c = BLUE
        draw.line([(s2x, s2y), (e2x, e2y)], fill=c, width=w)

    # Small arrow/path indicator on the right side of folder
    arrow_x = fx + fw - 140
    arrow_y = fy + fh // 2
    draw.line([(arrow_x, arrow_y - 30), (arrow_x + 40, arrow_y)], fill=BLUE_BRIGHT, width=3)
    draw.line([(arrow_x, arrow_y + 30), (arrow_x + 40, arrow_y)], fill=BLUE_BRIGHT, width=3)
    draw.line([(arrow_x - 40, arrow_y), (arrow_x + 40, arrow_y)], fill=BLUE_BRIGHT, width=3)

    return apply_mask(img)


# ============================================================
# ICON B: "Signal Tower"
# A vertical antenna/tower shape made of geometric segments,
# with concentric signal arcs emanating from the top.
# The tower structure incorporates \\ angles. Suggests
# broadcasting/connecting to a network endpoint.
# ============================================================
def icon_b():
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, (16, 18, 24), (10, 10, 14))

    cx = 512
    base_y = 800
    top_y = 240

    # Tower structure — angular, using backslash angles
    # Left leg
    draw.line([(cx - 120, base_y), (cx - 30, top_y + 120)], fill=MID_GRAY, width=8)
    # Right leg
    draw.line([(cx + 120, base_y), (cx + 30, top_y + 120)], fill=MID_GRAY, width=8)
    # Center mast
    draw.line([(cx, base_y - 40), (cx, top_y + 40)], fill=BLUE, width=12)

    # Cross beams
    for y in range(base_y - 80, top_y + 120, 100):
        t = (base_y - y) / (base_y - top_y)
        half_w = int(120 * (1 - t * 0.7))
        draw.line([(cx - half_w, y), (cx + half_w, y)], fill=(40, 40, 46), width=3)

    # Antenna tip
    draw.ellipse([cx - 14, top_y + 26, cx + 14, top_y + 54], fill=BLUE_BRIGHT)

    # Signal arcs from top
    for i, radius in enumerate([80, 140, 200, 260]):
        opacity = 1 - i * 0.22
        c = tuple(int(v * opacity) for v in BLUE)
        arc_y = top_y + 40
        # Draw arc segments (quarter circles)
        bbox = [cx - radius, arc_y - radius, cx + radius, arc_y + radius]
        draw.arc(bbox, start=210, end=250, fill=c, width=4)
        draw.arc(bbox, start=290, end=330, fill=c, width=4)

    # Small \\ notation at the base
    font = load_font("GeistMono-Bold.ttf", 48)
    text = "\\\\"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((cx - tw//2, base_y + 20), text, fill=BLUE_DIM, font=font)

    # Base platform
    draw.rounded_rectangle(
        [cx - 160, base_y - 10, cx + 160, base_y + 10],
        radius=5, fill=CHARCOAL
    )

    return apply_mask(img)


# ============================================================
# ICON C: "Pathfinder Compass"
# A circular compass/radar design with \\ as the needle.
# Concentric rings suggest scanning/discovery. The backslashes
# point like compass needles finding the network path.
# ============================================================
def icon_c():
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, (14, 16, 22), (18, 18, 20))

    cx, cy = 512, 512

    # Concentric rings
    for radius in [360, 300, 240, 180]:
        thickness = 2 if radius > 200 else 3
        c = BLUE_DEEP if radius > 250 else BLUE_DIM
        draw.ellipse([cx-radius, cy-radius, cx+radius, cy+radius], outline=c, width=thickness)

    # Tick marks around outer ring
    for angle in range(0, 360, 15):
        rad = math.radians(angle)
        inner_r = 345
        outer_r = 360
        if angle % 45 == 0:
            inner_r = 330
            c = BLUE
            w = 3
        else:
            c = MID_GRAY
            w = 1
        x1 = cx + int(inner_r * math.cos(rad))
        y1 = cy + int(inner_r * math.sin(rad))
        x2 = cx + int(outer_r * math.cos(rad))
        y2 = cy + int(outer_r * math.sin(rad))
        draw.line([(x1, y1), (x2, y2)], fill=c, width=w)

    # Cardinal labels
    font_small = load_font("GeistMono-Regular.ttf", 28)
    for label, angle in [("N", -90), ("E", 0), ("S", 90), ("W", 180)]:
        rad = math.radians(angle)
        lx = cx + int(390 * math.cos(rad))
        ly = cy + int(390 * math.sin(rad))
        bbox = draw.textbbox((0, 0), label, font=font_small)
        lw = bbox[2] - bbox[0]
        lh = bbox[3] - bbox[1]
        draw.text((lx - lw//2, ly - lh//2), label, fill=MID_GRAY, font=font_small)

    # Sweep/scan line (like radar)
    sweep_angle = math.radians(-35)
    sx = cx + int(340 * math.cos(sweep_angle))
    sy = cy + int(340 * math.sin(sweep_angle))
    draw.line([(cx, cy), (sx, sy)], fill=(*BLUE, ), width=2)
    # Sweep glow
    for a in range(-50, -35):
        rad = math.radians(a)
        ex = cx + int(340 * math.cos(rad))
        ey = cy + int(340 * math.sin(rad))
        alpha = (a + 50) / 15
        c = tuple(int(v * alpha * 0.15) for v in BLUE)
        draw.line([(cx, cy), (ex, ey)], fill=c, width=1)

    # The \\ needle — large, bold, the hero element
    sw = 36
    # First \
    draw.line([(cx - 60, cy - 160), (cx + 10, cy + 160)], fill=BLUE, width=sw)
    draw.ellipse([cx-60-sw//2, cy-160-sw//2, cx-60+sw//2, cy-160+sw//2], fill=BLUE)
    draw.ellipse([cx+10-sw//2, cy+160-sw//2, cx+10+sw//2, cy+160+sw//2], fill=BLUE)
    # Second \
    draw.line([(cx + 50, cy - 160), (cx + 120, cy + 160)], fill=BLUE_BRIGHT, width=sw)
    draw.ellipse([cx+50-sw//2, cy-160-sw//2, cx+50+sw//2, cy-160+sw//2], fill=BLUE_BRIGHT)
    draw.ellipse([cx+120-sw//2, cy+160-sw//2, cx+120+sw//2, cy+160+sw//2], fill=BLUE_BRIGHT)

    # Center hub
    draw.ellipse([cx-20, cy-20, cx+20, cy+20], fill=DARK_BG, outline=BLUE, width=3)
    draw.ellipse([cx-6, cy-6, cx+6, cy+6], fill=WHITE)

    return apply_mask(img)


# ============================================================
# ICON D: "Glass Tile"
# A glossy, beveled tile with a bold N letterform that has
# the vertical stroke replaced by a \. Inspired by macOS
# system app icons (Notes, News). Gradient blue surface
# with subtle inner shadow and highlight.
# ============================================================
def icon_d():
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)

    # Fill with rich blue gradient (like macOS system icons)
    for y in range(SIZE):
        t = y / SIZE
        r = int(0 + 0 * t)
        g = int(90 + (50 - 90) * t)
        b = int(255 + (180 - 255) * t)
        draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

    # Inner bevel highlight (top edge lighter)
    for i in range(30):
        alpha = 1 - i / 30
        c = (int(255 * alpha * 0.15), int(255 * alpha * 0.15), int(255 * alpha * 0.15))
        y = i
        draw.line([(40, y + 40), (SIZE - 40, y + 40)], fill=c)

    # Inner shadow (bottom edge darker)
    for i in range(30):
        alpha = 1 - i / 30
        c = (0, 0, int(30 * alpha))
        y = SIZE - i
        draw.line([(40, y - 40), (SIZE - 40, y - 40)], fill=c)

    # Draw the "N" letterform with \\ as the diagonal
    stroke = 70
    margin_x = 240
    margin_top = 200
    margin_bottom = 780

    letter_color = WHITE

    # Left vertical of N
    draw.line([(margin_x, margin_top), (margin_x, margin_bottom)], fill=letter_color, width=stroke)
    draw.ellipse([margin_x-stroke//2, margin_top-stroke//2, margin_x+stroke//2, margin_top+stroke//2], fill=letter_color)
    draw.ellipse([margin_x-stroke//2, margin_bottom-stroke//2, margin_x+stroke//2, margin_bottom+stroke//2], fill=letter_color)

    # Right vertical of N
    right_x = SIZE - margin_x
    draw.line([(right_x, margin_top), (right_x, margin_bottom)], fill=letter_color, width=stroke)
    draw.ellipse([right_x-stroke//2, margin_top-stroke//2, right_x+stroke//2, margin_top+stroke//2], fill=letter_color)
    draw.ellipse([right_x-stroke//2, margin_bottom-stroke//2, right_x+stroke//2, margin_bottom+stroke//2], fill=letter_color)

    # Diagonal stroke of N (the backslash!)
    draw.line([(margin_x, margin_top), (right_x, margin_bottom)], fill=letter_color, width=stroke)

    return apply_mask(img)


# ============================================================
# ICON E: "Keyhole Path"
# A keyhole shape where the shaft of the key is formed by
# two parallel lines (\\). Represents unlocking access to
# network shares. Dark with blue luminous keyhole.
# ============================================================
def icon_e():
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)
    gradient_bg(draw, (20, 20, 26), (12, 12, 14))

    cx, cy_head = 512, 340
    head_radius = 160

    # Outer circle glow
    for r in range(head_radius + 60, head_radius, -1):
        factor = 1 - (r - head_radius) / 60
        c = tuple(int(v * factor * 0.2) for v in BLUE)
        draw.ellipse([cx - r, cy_head - r, cx + r, cy_head + r], fill=c)

    # Keyhole head circle — outline
    draw.ellipse(
        [cx - head_radius, cy_head - head_radius, cx + head_radius, cy_head + head_radius],
        outline=BLUE, width=6
    )
    # Inner circle
    draw.ellipse(
        [cx - head_radius + 30, cy_head - head_radius + 30,
         cx + head_radius - 30, cy_head + head_radius - 30],
        outline=BLUE_DIM, width=2
    )

    # Keyhole center — inner glow
    inner_r = 50
    for r in range(inner_r + 30, 0, -1):
        factor = max(0, 1 - r / (inner_r + 30))
        c = tuple(int(v * factor * 0.5) for v in BLUE_BRIGHT)
        draw.ellipse([cx - r, cy_head - r, cx + r, cy_head + r], fill=c)
    draw.ellipse([cx - inner_r, cy_head - inner_r, cx + inner_r, cy_head + inner_r], fill=BLUE)

    # Key shaft — two parallel lines forming \\ going downward
    shaft_top = cy_head + head_radius - 20
    shaft_bottom = 820
    shaft_w = 28

    # Left shaft line (slight angle to suggest \)
    draw.line([(cx - 35, shaft_top), (cx - 55, shaft_bottom)], fill=BLUE, width=shaft_w)
    draw.ellipse([cx-55-shaft_w//2, shaft_bottom-shaft_w//2, cx-55+shaft_w//2, shaft_bottom+shaft_w//2], fill=BLUE)

    # Right shaft line
    draw.line([(cx + 35, shaft_top), (cx + 15, shaft_bottom)], fill=BLUE, width=shaft_w)
    draw.ellipse([cx+15-shaft_w//2, shaft_bottom-shaft_w//2, cx+15+shaft_w//2, shaft_bottom+shaft_w//2], fill=BLUE)

    # Key teeth (horizontal notches on the shaft)
    for y in [620, 690, 740]:
        draw.line([(cx + 15 + shaft_w//2, y), (cx + 15 + shaft_w//2 + 35, y)], fill=BLUE, width=6)
        draw.line([(cx + 15 + shaft_w//2 + 35, y), (cx + 15 + shaft_w//2 + 35, y + 25)], fill=BLUE, width=6)

    # Lock plate outline
    plate_w, plate_h = 200, 400
    draw.rounded_rectangle(
        [cx - plate_w//2, cy_head - 40, cx + plate_w//2, cy_head + plate_h],
        radius=30, outline=CHARCOAL, width=2
    )

    return apply_mask(img)


# Generate all icons
if __name__ == "__main__":
    icons = [
        ("v2_a_folder_portal.png", icon_a, "A: Folder Portal"),
        ("v2_b_signal_tower.png", icon_b, "B: Signal Tower"),
        ("v2_c_pathfinder_compass.png", icon_c, "C: Pathfinder Compass"),
        ("v2_d_glass_tile_N.png", icon_d, "D: Glass Tile N"),
        ("v2_e_keyhole_path.png", icon_e, "E: Keyhole Path"),
    ]

    for filename, func, desc in icons:
        print(f"Generating {desc}...")
        icon = func()
        path = os.path.join(OUT_DIR, filename)
        icon.save(path, "PNG")
        print(f"  Saved: {path}")

    print("\nDone! All 5 v2 icons generated.")
