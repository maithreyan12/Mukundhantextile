#!/usr/bin/env python3
"""
Creates Play Store tablet screenshots from phone screenshots.
Frames phone screenshots on a branded tablet-like canvas.
"""
from PIL import Image, ImageDraw, ImageFilter
import os

SRC = '/Users/maithreyan/projects/Mukundhantextile'
OUT = os.path.join(SRC, 'tablet_screenshots')
os.makedirs(OUT, exist_ok=True)

# Brand colour (dark rich maroon/gold — textile brand feel)
BG_COLOR   = (28, 20, 14)      # Deep dark brown
ACCENT     = (180, 140, 70)    # Gold accent
OVERLAY    = (40, 28, 16, 200) # Semi-transparent overlay

# Phone screenshots to use
SCREENS = [
    ('screen_home.png',    '01_home'),
    ('screen_browse.png',  '02_browse'),
    ('screen_cart.png',    '03_cart'),
    ('screen_profile.png', '04_profile'),
    ('ss_product.png',     '05_product'),
]

# Target sizes: (width, height) — Play Store landscape tablet
SIZES = [
    ('7inch',  1024, 600),
    ('10inch', 1280, 800),
]

def rounded_rect_mask(size, radius):
    """Create a rounded-rectangle mask."""
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size[0]-1, size[1]-1], radius=radius, fill=255)
    return mask

def make_tablet_screenshot(phone_img_path, out_path, canvas_w, canvas_h):
    # Load phone screenshot
    phone = Image.open(phone_img_path).convert('RGBA')
    ph_w, ph_h = phone.size  # e.g. 1080x2400

    # ── Canvas ────────────────────────────────────────────────────
    canvas = Image.new('RGBA', (canvas_w, canvas_h), BG_COLOR + (255,))
    draw = ImageDraw.Draw(canvas)

    # Subtle gradient overlay (darker on right)
    for x in range(canvas_w):
        alpha = int(60 * (x / canvas_w))
        draw.line([(x, 0), (x, canvas_h)], fill=(0, 0, 0, alpha))

    # Gold accent lines
    draw.rectangle([0, 0, canvas_w-1, 3], fill=ACCENT + (255,))
    draw.rectangle([0, canvas_h-4, canvas_w-1, canvas_h-1], fill=ACCENT + (255,))
    draw.rectangle([0, 0, 3, canvas_h-1], fill=ACCENT + (255,))
    draw.rectangle([canvas_w-4, 0, canvas_w-1, canvas_h-1], fill=ACCENT + (255,))

    # ── Phone frame ───────────────────────────────────────────────
    # Scale phone screenshot to fit ~80% of canvas height
    target_h = int(canvas_h * 0.88)
    scale = target_h / ph_h
    target_w = int(ph_w * scale)
    phone_resized = phone.resize((target_w, target_h), Image.LANCZOS)

    # Add drop shadow behind phone
    shadow_offset = 8
    shadow = Image.new('RGBA', (target_w + shadow_offset*2, target_h + shadow_offset*2), (0,0,0,0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [shadow_offset, shadow_offset, target_w + shadow_offset, target_h + shadow_offset],
        radius=18, fill=(0, 0, 0, 120)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=10))

    # Center phone on right side of canvas
    margin_right = int(canvas_w * 0.04)
    phone_x = canvas_w - target_w - margin_right
    phone_y = (canvas_h - target_h) // 2

    # Paste shadow
    canvas.alpha_composite(shadow, (phone_x - shadow_offset, phone_y - shadow_offset))

    # Apply rounded corners to phone screenshot
    phone_mask = rounded_rect_mask((target_w, target_h), radius=20)
    phone_rgba = phone_resized.copy()
    phone_rgba.putalpha(phone_mask)

    # Paste phone screenshot
    canvas.alpha_composite(phone_rgba, (phone_x, phone_y))

    # ── Brand text on left ────────────────────────────────────────
    # Draw brand name (simple text, no extra font needed)
    txt_draw = ImageDraw.Draw(canvas)

    # Brand label area
    label_x = int(canvas_w * 0.04)
    label_y = int(canvas_h * 0.30)

    # Gold divider line
    txt_draw.rectangle([label_x, label_y - 20, label_x + 60, label_y - 17], fill=ACCENT + (255,))

    # Simple text (PIL default font — always available)
    from PIL import ImageFont
    try:
        font_lg = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', size=int(canvas_h * 0.07))
        font_sm = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', size=int(canvas_h * 0.04))
        font_xs = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', size=int(canvas_h * 0.028))
    except:
        font_lg = font_sm = font_xs = ImageFont.load_default()

    txt_draw.text((label_x, label_y), "Mugundhan", font=font_lg, fill=(255, 255, 255, 255))
    txt_draw.text((label_x, label_y + int(canvas_h * 0.09)), "Tex & Readymades", font=font_sm, fill=ACCENT + (255,))
    txt_draw.text((label_x, label_y + int(canvas_h * 0.16)), "Shop Smart, Live Better", font=font_xs, fill=(180, 170, 155, 220))

    # ── Save ──────────────────────────────────────────────────────
    final = canvas.convert('RGB')
    final.save(out_path, 'PNG', optimize=True)
    print(f'  ✅ {out_path}')

def main():
    print('🖼️  Creating tablet screenshots...\n')
    for size_name, w, h in SIZES:
        print(f'📱 {size_name} ({w}x{h}):')
        for src_file, label in SCREENS:
            src_path = os.path.join(SRC, src_file)
            if not os.path.exists(src_path):
                print(f'  ⚠️  Not found: {src_file}')
                continue
            out_path = os.path.join(OUT, f'{size_name}_{label}.png')
            make_tablet_screenshot(src_path, out_path, w, h)
        print()
    print(f'🎉 Done! All screenshots saved to:\n   {OUT}')

if __name__ == '__main__':
    main()
