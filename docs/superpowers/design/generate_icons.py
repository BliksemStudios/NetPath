#!/usr/bin/env python3
"""Generate 5 NetPath app icon options following Voltaic Precision design language."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

FONTS_DIR = "/Users/jeandre/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/833b45ed-3185-4a5e-9c94-932a74643858/de29a6d6-ab2b-4a5f-9127-0440efa28656/skills/canvas-design/canvas-fonts"
OUT_DIR = "/Users/jeandre/source/BliksemStudios/MacPathExplorer/docs/superpowers/design/icons"

SIZE = 1024
BLUE = (0, 102, 255)        # #0066FF
DARK_BG = (22, 22, 24)      # near-black
DARKER = (16, 16, 18)
MID_GRAY = (44, 44, 46)
LIGHT_GRAY = (88, 88, 92)
WHITE = (240, 240, 245)
BLUE_DIM = (0, 60, 150)
BLUE_GLOW = (0, 130, 255)

def load_font(name, size):
    try:
        return ImageFont.truetype(os.path.join(FONTS_DIR, name), size)
    except:
        return ImageFont.load_default()

def rounded_rect_mask(size, radius):
    """Create a rounded rectangle mask for macOS icon shape."""
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    return mask

def apply_mask(img, radius=180):
    """Apply macOS-style rounded rectangle mask."""
    mask = rounded_rect_mask(SIZE, radius)
    result = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    result.paste(img, mask=mask)
    return result

def draw_glow_line(draw, start, end, color, width=4, glow_radius=12):
    """Draw a line with subtle glow effect."""
    for i in range(glow_radius, 0, -1):
        alpha = int(30 * (1 - i / glow_radius))
        glow_color = (*color[:3], alpha)
        # Can't do alpha with regular draw, simulate with dimmer colors
        factor = 1 - (i / glow_radius) * 0.7
        gc = tuple(int(c * factor) for c in color[:3])
        draw.line([start, end], fill=gc, width=width + i * 2)
    draw.line([start, end], fill=color, width=width)


# ============================================================
# ICON A: "Circuit Backslash" — Two bold \\ strokes forming a
# path, with thin circuit-like grid lines, on dark bg
# ============================================================
def icon_a():
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)

    # Subtle grid pattern
    for i in range(0, SIZE, 64):
        draw.line([(i, 0), (i, SIZE)], fill=(30, 30, 32), width=1)
        draw.line([(0, i), (SIZE, i)], fill=(30, 30, 32), width=1)

    # Two bold backslash strokes — the \\ symbol
    stroke_width = 72
    # First backslash
    x1_start, y1_start = 260, 180
    x1_end, y1_end = 520, 820
    draw.line([(x1_start, y1_start), (x1_end, y1_end)], fill=BLUE, width=stroke_width)
    # Rounded caps
    draw.ellipse([x1_start - stroke_width//2, y1_start - stroke_width//2,
                  x1_start + stroke_width//2, y1_start + stroke_width//2], fill=BLUE)
    draw.ellipse([x1_end - stroke_width//2, y1_end - stroke_width//2,
                  x1_end + stroke_width//2, y1_end + stroke_width//2], fill=BLUE)

    # Second backslash
    x2_start, y2_start = 500, 180
    x2_end, y2_end = 760, 820
    draw.line([(x2_start, y2_start), (x2_end, y2_end)], fill=BLUE, width=stroke_width)
    draw.ellipse([x2_start - stroke_width//2, y2_start - stroke_width//2,
                  x2_start + stroke_width//2, y2_start + stroke_width//2], fill=BLUE)
    draw.ellipse([x2_end - stroke_width//2, y2_end - stroke_width//2,
                  x2_end + stroke_width//2, y2_end + stroke_width//2], fill=BLUE)

    # Small circuit nodes at intersections with grid
    for y in range(256, 800, 128):
        for bx in [(260, 520), (500, 760)]:
            t = (y - 180) / 640
            x = int(bx[0] + (bx[1] - bx[0]) * t)
            draw.ellipse([x-6, y-6, x+6, y+6], fill=WHITE)

    return apply_mask(img)


# ============================================================
# ICON B: "Geometric Path" — Abstract \\ inside a rounded
# square with layered depth, dark gradient
# ============================================================
def icon_b():
    img = Image.new('RGB', (SIZE, SIZE), DARKER)
    draw = ImageDraw.Draw(img)

    # Background gradient (simulate with bands)
    for y in range(SIZE):
        factor = 1 - (y / SIZE) * 0.3
        r = int(DARKER[0] * factor)
        g = int(DARKER[1] * factor)
        b = int(DARKER[2] * factor)
        draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

    # Inner rounded rectangle (subtle border)
    margin = 120
    draw.rounded_rectangle(
        [margin, margin, SIZE - margin, SIZE - margin],
        radius=80, outline=MID_GRAY, width=2
    )

    # Backslash pair — thinner, more elegant
    sw = 56
    # First \
    draw.line([(310, 250), (480, 770)], fill=BLUE, width=sw)
    draw.ellipse([310-sw//2, 250-sw//2, 310+sw//2, 250+sw//2], fill=BLUE)
    draw.ellipse([480-sw//2, 770-sw//2, 480+sw//2, 770+sw//2], fill=BLUE)

    # Second \
    draw.line([(530, 250), (700, 770)], fill=BLUE, width=sw)
    draw.ellipse([530-sw//2, 250-sw//2, 530+sw//2, 250+sw//2], fill=BLUE)
    draw.ellipse([700-sw//2, 770-sw//2, 700+sw//2, 770+sw//2], fill=BLUE)

    # Subtle horizontal line through center (like a network path)
    draw.line([(margin + 40, 512), (SIZE - margin - 40, 512)], fill=(*BLUE_DIM, ), width=2)

    # Small dots at endpoints
    for pos in [(310, 250), (480, 770), (530, 250), (700, 770)]:
        draw.ellipse([pos[0]-8, pos[1]-8, pos[0]+8, pos[1]+8], fill=WHITE)

    return apply_mask(img)


# ============================================================
# ICON C: "Network Node" — \\ with branching paths radiating
# from a central node, suggesting network connectivity
# ============================================================
def icon_c():
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)

    cx, cy = 512, 512

    # Radiating lines from center (network paths)
    angles = [30, 75, 120, 165, 210, 255, 300, 345]
    for angle in angles:
        rad = math.radians(angle)
        ex = cx + int(400 * math.cos(rad))
        ey = cy + int(400 * math.sin(rad))
        draw.line([(cx, cy), (ex, ey)], fill=(35, 35, 40), width=2)
        # Endpoint node
        draw.ellipse([ex-5, ey-5, ex+5, ey+5], fill=MID_GRAY)

    # Central glow circle
    for r in range(80, 0, -1):
        alpha_factor = 1 - (r / 80)
        c = int(BLUE[2] * alpha_factor * 0.15)
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(0, int(c*0.4), c))

    # Bold \\ in center
    sw = 64
    offset_x = -20
    # First \
    s1 = (cx - 100 + offset_x, cy - 200)
    e1 = (cx + 20 + offset_x, cy + 200)
    draw.line([s1, e1], fill=BLUE, width=sw)
    draw.ellipse([s1[0]-sw//2, s1[1]-sw//2, s1[0]+sw//2, s1[1]+sw//2], fill=BLUE)
    draw.ellipse([e1[0]-sw//2, e1[1]-sw//2, e1[0]+sw//2, e1[1]+sw//2], fill=BLUE)

    # Second \
    s2 = (cx + 60 + offset_x, cy - 200)
    e2 = (cx + 180 + offset_x, cy + 200)
    draw.line([s2, e2], fill=BLUE, width=sw)
    draw.ellipse([s2[0]-sw//2, s2[1]-sw//2, s2[0]+sw//2, s2[1]+sw//2], fill=BLUE)
    draw.ellipse([e2[0]-sw//2, e2[1]-sw//2, e2[0]+sw//2, e2[1]+sw//2], fill=BLUE)

    # Central node dot
    draw.ellipse([cx-12, cy-12, cx+12, cy+12], fill=WHITE)

    return apply_mask(img)


# ============================================================
# ICON D: "Stacked Planes" — \\ rendered as 3D extruded
# strokes with depth, isometric perspective feel
# ============================================================
def icon_d():
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)

    # Background: subtle diagonal hatching
    for i in range(-SIZE, SIZE * 2, 48):
        draw.line([(i, 0), (i + SIZE, SIZE)], fill=(25, 25, 27), width=1)

    sw = 52
    depth = 28
    depth_color = BLUE_DIM

    # Draw "3D" backslashes — shadow layer first
    for offset in range(depth, 0, -1):
        factor = offset / depth
        c = tuple(int(v * (0.3 + 0.3 * factor)) for v in BLUE)
        # First \
        draw.line([(280 + offset, 200 + offset), (470 + offset, 780 + offset)], fill=c, width=sw)
        # Second \
        draw.line([(500 + offset, 200 + offset), (690 + offset, 780 + offset)], fill=c, width=sw)

    # Top layer (crisp)
    draw.line([(280, 200), (470, 780)], fill=BLUE, width=sw)
    draw.ellipse([280-sw//2, 200-sw//2, 280+sw//2, 200+sw//2], fill=BLUE)
    draw.ellipse([470-sw//2, 780-sw//2, 470+sw//2, 780+sw//2], fill=BLUE)

    draw.line([(500, 200), (690, 780)], fill=BLUE, width=sw)
    draw.ellipse([500-sw//2, 200-sw//2, 500+sw//2, 200+sw//2], fill=BLUE)
    draw.ellipse([690-sw//2, 780-sw//2, 690+sw//2, 780+sw//2], fill=BLUE)

    # Highlight on top edge
    draw.line([(280, 200), (470, 780)], fill=BLUE_GLOW, width=4)
    draw.line([(500, 200), (690, 780)], fill=BLUE_GLOW, width=4)

    return apply_mask(img)


# ============================================================
# ICON E: "Minimal Monogram" — Clean, Swiss-style: just \\
# as ultra-refined typography on pure dark, with a single
# accent line
# ============================================================
def icon_e():
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)

    # Load a bold monospace font for the backslashes
    font = load_font("GeistMono-Bold.ttf", 420)

    # Draw the \\ text centered
    text = "\\\\"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (SIZE - tw) // 2
    ty = (SIZE - th) // 2 - 40

    draw.text((tx, ty), text, fill=BLUE, font=font)

    # Single horizontal accent line below
    line_y = ty + th + 50
    line_margin = 200
    draw.line([(line_margin, line_y), (SIZE - line_margin, line_y)], fill=BLUE, width=3)

    # Small label text
    label_font = load_font("GeistMono-Regular.ttf", 36)
    label = "NETPATH"
    lbox = draw.textbbox((0, 0), label, font=label_font)
    lw = lbox[2] - lbox[0]
    draw.text(((SIZE - lw) // 2, line_y + 20), label, fill=LIGHT_GRAY, font=label_font)

    return apply_mask(img)


# Generate all icons
if __name__ == "__main__":
    icons = [
        ("icon_a_circuit_backslash.png", icon_a, "Circuit Backslash — Grid pattern with bold \\\\ strokes and circuit nodes"),
        ("icon_b_geometric_path.png", icon_b, "Geometric Path — Elegant \\\\ inside bordered frame with depth"),
        ("icon_c_network_node.png", icon_c, "Network Node — \\\\ at center of radiating network paths"),
        ("icon_d_stacked_planes.png", icon_d, "Stacked Planes — 3D extruded \\\\ with depth and glow"),
        ("icon_e_minimal_monogram.png", icon_e, "Minimal Monogram — Swiss-style typography, pure and clean"),
    ]

    for filename, func, desc in icons:
        print(f"Generating {desc}...")
        icon = func()
        path = os.path.join(OUT_DIR, filename)
        icon.save(path, "PNG")
        print(f"  Saved: {path}")

    print("\nDone! All 5 icons generated.")
