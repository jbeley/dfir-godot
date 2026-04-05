#!/usr/bin/env python3
"""Generate pixel art sprites for DFIR Simulator.
16-bit SNES style, small sprites for 480x270 viewport.
"""

from PIL import Image, ImageDraw
import os

SPRITES_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sprites')

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def save(img, *path_parts):
    full = os.path.join(SPRITES_DIR, *path_parts)
    ensure_dir(os.path.dirname(full))
    img.save(full)
    print(f"  Created {os.path.join(*path_parts)}")


# --- Color palettes ---
SKIN = (235, 200, 165)
HAIR_DARK = (50, 35, 25)
HAIR_LIGHT = (180, 140, 80)
SHIRT_BLUE = (60, 90, 140)
SHIRT_GREEN = (60, 120, 80)
PANTS = (45, 45, 60)
SHOES = (40, 30, 25)
TRANSPARENT = (0, 0, 0, 0)

# Furniture
WOOD_DARK = (80, 55, 35)
WOOD_MED = (120, 85, 50)
WOOD_LIGHT = (160, 120, 75)
METAL_DARK = (60, 65, 75)
METAL_LIGHT = (130, 135, 145)
SCREEN_OFF = (25, 35, 45)
SCREEN_ON = (40, 100, 40)
SCREEN_BLUE = (50, 80, 140)
BED_BLUE = (65, 65, 130)
BED_WHITE = (210, 210, 220)
FABRIC_RED = (150, 50, 50)
CORK = (160, 130, 90)
PAPER_WHITE = (230, 230, 215)
PAPER_YELLOW = (230, 220, 160)
PAPER_RED = (220, 180, 180)

# Cat
CAT_ORANGE = (210, 150, 60)
CAT_DARK = (170, 110, 40)
CAT_WHITE = (240, 235, 225)
CAT_NOSE = (200, 130, 130)
CAT_EYE = (80, 160, 80)

# Floor/walls
FLOOR_WOOD = (140, 110, 75)
FLOOR_DARK = (110, 85, 58)
WALL_COLOR = (75, 70, 80)
RUG_RED = (120, 45, 40)
RUG_BORDER = (90, 30, 28)
WINDOW_SKY = (120, 160, 200)
WINDOW_FRAME = (180, 175, 165)


def make_player_spritesheet():
    """Create a 4-direction player sprite sheet (16x20 per frame, 4 frames per direction)."""
    W, H = 16, 20
    COLS, ROWS = 4, 4  # 4 frames x 4 directions (down, left, right, up)
    sheet = Image.new('RGBA', (W * COLS, H * ROWS), TRANSPARENT)

    for direction in range(4):  # 0=down, 1=left, 2=right, 3=up
        for frame in range(4):
            x0 = frame * W
            y0 = direction * H
            img = Image.new('RGBA', (W, H), TRANSPARENT)
            d = ImageDraw.Draw(img)

            # Walk bob
            bob = 1 if frame % 2 == 0 else 0

            # Hair
            d.rectangle([5, 1+bob, 10, 4+bob], fill=HAIR_DARK)

            # Head
            d.rectangle([5, 3+bob, 10, 7+bob], fill=SKIN)

            # Eyes (front-facing for down, back for up)
            if direction == 0:  # down
                d.point((6, 5+bob), fill=(40, 40, 50))
                d.point((9, 5+bob), fill=(40, 40, 50))
            elif direction == 3:  # up
                pass  # no eyes visible
            elif direction == 1:  # left
                d.point((5, 5+bob), fill=(40, 40, 50))
            elif direction == 2:  # right
                d.point((10, 5+bob), fill=(40, 40, 50))

            # Shirt
            d.rectangle([4, 8+bob, 11, 13+bob], fill=SHIRT_BLUE)

            # Arms
            if frame == 1:
                d.rectangle([3, 8+bob, 3, 12+bob], fill=SHIRT_BLUE)
                d.rectangle([12, 9+bob, 12, 13+bob], fill=SHIRT_BLUE)
            elif frame == 3:
                d.rectangle([3, 9+bob, 3, 13+bob], fill=SHIRT_BLUE)
                d.rectangle([12, 8+bob, 12, 12+bob], fill=SHIRT_BLUE)
            else:
                d.rectangle([3, 9+bob, 3, 12+bob], fill=SHIRT_BLUE)
                d.rectangle([12, 9+bob, 12, 12+bob], fill=SHIRT_BLUE)

            # Pants
            d.rectangle([5, 14+bob, 10, 17+bob], fill=PANTS)

            # Legs (walk cycle)
            if frame == 1:
                d.rectangle([5, 16+bob, 6, 18+bob], fill=PANTS)
                d.rectangle([9, 15+bob, 10, 17+bob], fill=PANTS)
            elif frame == 3:
                d.rectangle([5, 15+bob, 6, 17+bob], fill=PANTS)
                d.rectangle([9, 16+bob, 10, 18+bob], fill=PANTS)

            # Shoes
            d.rectangle([5, 18, 7, 19], fill=SHOES)
            d.rectangle([8, 18, 10, 19], fill=SHOES)

            sheet.paste(img, (x0, y0))

    save(sheet, 'characters', 'player.png')


def make_cat():
    """Create a cat sprite (16x12)."""
    img = Image.new('RGBA', (16, 12), TRANSPARENT)
    d = ImageDraw.Draw(img)

    # Body
    d.rectangle([3, 4, 12, 9], fill=CAT_ORANGE)
    d.rectangle([4, 3, 11, 4], fill=CAT_ORANGE)  # back

    # Head
    d.rectangle([1, 2, 5, 6], fill=CAT_ORANGE)

    # Ears
    d.point((1, 1), fill=CAT_DARK)
    d.point((5, 1), fill=CAT_DARK)

    # Eyes
    d.point((2, 3), fill=CAT_EYE)
    d.point((4, 3), fill=CAT_EYE)

    # Nose
    d.point((3, 4), fill=CAT_NOSE)

    # Tail
    d.rectangle([12, 2, 14, 3], fill=CAT_DARK)
    d.point((15, 1), fill=CAT_DARK)

    # Stripes
    d.point((6, 3), fill=CAT_DARK)
    d.point((8, 3), fill=CAT_DARK)
    d.point((10, 3), fill=CAT_DARK)

    # Legs
    d.rectangle([4, 10, 5, 11], fill=CAT_ORANGE)
    d.rectangle([10, 10, 11, 11], fill=CAT_ORANGE)

    # Belly
    d.rectangle([5, 7, 10, 8], fill=CAT_WHITE)

    save(img, 'characters', 'cat.png')


def make_desk():
    """Desk with monitor (48x40)."""
    img = Image.new('RGBA', (48, 40), TRANSPARENT)
    d = ImageDraw.Draw(img)

    # Desk surface
    d.rectangle([0, 18, 47, 24], fill=WOOD_MED)
    d.rectangle([0, 18, 47, 19], fill=WOOD_LIGHT)

    # Legs
    d.rectangle([2, 24, 4, 39], fill=WOOD_DARK)
    d.rectangle([43, 24, 45, 39], fill=WOOD_DARK)

    # Drawer
    d.rectangle([18, 24, 34, 32], fill=WOOD_MED)
    d.rectangle([24, 27, 28, 28], fill=METAL_LIGHT)

    # Monitor
    d.rectangle([14, 2, 34, 17], fill=METAL_DARK)
    d.rectangle([16, 3, 32, 15], fill=SCREEN_ON)

    # Terminal text on screen
    for y in range(4, 14, 2):
        w = 10 + (y * 3 % 7)
        d.rectangle([17, y, 17 + w, y], fill=(80, 200, 80))

    # Monitor stand
    d.rectangle([22, 17, 26, 18], fill=METAL_DARK)

    # Keyboard
    d.rectangle([10, 20, 26, 22], fill=METAL_LIGHT)

    # Mouse
    d.rectangle([30, 20, 33, 22], fill=METAL_LIGHT)

    # Coffee mug
    d.rectangle([38, 14, 42, 18], fill=(220, 220, 210))
    d.rectangle([42, 15, 43, 17], fill=(220, 220, 210))
    d.rectangle([39, 13, 41, 14], fill=(140, 90, 50))  # coffee

    save(img, 'office', 'desk.png')


def make_bed():
    """Bed (40x52)."""
    img = Image.new('RGBA', (40, 52), TRANSPARENT)
    d = ImageDraw.Draw(img)

    # Frame
    d.rectangle([0, 0, 39, 51], fill=WOOD_MED)
    d.rectangle([2, 2, 37, 49], fill=BED_BLUE)

    # Pillow
    d.rectangle([6, 3, 33, 12], fill=BED_WHITE)
    d.rectangle([7, 4, 18, 11], fill=(200, 200, 210))
    d.rectangle([21, 4, 32, 11], fill=(200, 200, 210))

    # Blanket
    d.rectangle([4, 14, 35, 46], fill=(80, 80, 150))
    d.rectangle([4, 14, 35, 16], fill=(100, 100, 170))

    # Blanket fold
    d.rectangle([4, 14, 35, 15], fill=(110, 110, 180))

    save(img, 'office', 'bed.png')


def make_evidence_board():
    """Cork evidence board with pinned notes (64x32)."""
    img = Image.new('RGBA', (64, 32), TRANSPARENT)
    d = ImageDraw.Draw(img)

    # Cork board
    d.rectangle([0, 0, 63, 31], fill=CORK)
    d.rectangle([0, 0, 63, 0], fill=WOOD_DARK)
    d.rectangle([0, 31, 63, 31], fill=WOOD_DARK)
    d.rectangle([0, 0, 0, 31], fill=WOOD_DARK)
    d.rectangle([63, 0, 63, 31], fill=WOOD_DARK)

    # Pinned notes
    d.rectangle([4, 4, 18, 14], fill=PAPER_WHITE)
    d.point((11, 3), fill=(220, 50, 50))  # red pin

    d.rectangle([22, 6, 36, 18], fill=PAPER_YELLOW)
    d.point((29, 5), fill=(50, 50, 220))  # blue pin

    d.rectangle([40, 3, 52, 12], fill=PAPER_RED)
    d.point((46, 2), fill=(50, 180, 50))  # green pin

    d.rectangle([44, 16, 58, 26], fill=PAPER_WHITE)
    d.point((51, 15), fill=(220, 180, 50))  # yellow pin

    # String connections
    d.line([(11, 9), (29, 12)], fill=(180, 50, 50))
    d.line([(29, 12), (46, 8)], fill=(180, 50, 50))

    save(img, 'office', 'evidence_board.png')


def make_coffee_station():
    """Coffee maker and table (24x24)."""
    img = Image.new('RGBA', (24, 24), TRANSPARENT)
    d = ImageDraw.Draw(img)

    # Counter
    d.rectangle([0, 10, 23, 23], fill=WOOD_MED)
    d.rectangle([0, 10, 23, 11], fill=WOOD_LIGHT)

    # Coffee maker
    d.rectangle([2, 2, 12, 10], fill=METAL_DARK)
    d.rectangle([4, 4, 10, 8], fill=(60, 60, 65))
    d.point((7, 3), fill=(220, 50, 50))  # power light
    d.rectangle([5, 8, 9, 10], fill=METAL_LIGHT)  # drip tray

    # Mug
    d.rectangle([16, 6, 21, 10], fill=(220, 220, 210))
    d.rectangle([21, 7, 22, 9], fill=(220, 220, 210))  # handle

    save(img, 'office', 'coffee.png')


def make_phone():
    """Smartphone (12x18)."""
    img = Image.new('RGBA', (12, 18), TRANSPARENT)
    d = ImageDraw.Draw(img)

    # Phone body
    d.rectangle([0, 0, 11, 17], fill=(30, 30, 35))
    d.rectangle([1, 1, 10, 14], fill=SCREEN_BLUE)

    # Screen content (email icon)
    d.rectangle([3, 4, 8, 8], fill=(230, 230, 240))
    d.line([(3, 4), (5, 6)], fill=(100, 100, 120))
    d.line([(8, 4), (6, 6)], fill=(100, 100, 120))

    # Notification dot
    d.rectangle([8, 3, 9, 4], fill=(220, 60, 60))

    # Home button
    d.rectangle([4, 15, 7, 16], fill=(50, 50, 55))

    save(img, 'office', 'phone.png')


def make_bookshelf():
    """Bookshelf (48x56)."""
    img = Image.new('RGBA', (48, 56), TRANSPARENT)
    d = ImageDraw.Draw(img)

    # Frame
    d.rectangle([0, 0, 47, 55], fill=WOOD_DARK)
    d.rectangle([2, 2, 45, 53], fill=WOOD_MED)

    # Shelves
    for sy in [2, 18, 36]:
        d.rectangle([2, sy + 14, 45, sy + 16], fill=WOOD_DARK)

    # Books on each shelf
    book_colors = [
        (180, 50, 50), (50, 80, 150), (50, 130, 50), (150, 100, 50),
        (100, 50, 130), (50, 130, 130), (180, 130, 50), (130, 50, 80),
        (80, 80, 130), (50, 100, 80), (180, 80, 80), (60, 60, 120),
    ]
    for shelf in range(3):
        sy = 2 + shelf * 18
        x = 4
        for i in range(4):
            color = book_colors[(shelf * 4 + i) % len(book_colors)]
            bw = 6 + (i % 3)
            d.rectangle([x, sy + 1, x + bw, sy + 13], fill=color)
            # Spine detail
            d.rectangle([x + 1, sy + 3, x + bw - 1, sy + 4], fill=(min(255, color[0]+40), min(255, color[1]+40), min(255, color[2]+40)))
            x += bw + 2

    save(img, 'office', 'bookshelf.png')


def make_window():
    """Window with sky view (52x40)."""
    img = Image.new('RGBA', (52, 40), TRANSPARENT)
    d = ImageDraw.Draw(img)

    # Frame
    d.rectangle([0, 0, 51, 39], fill=WINDOW_FRAME)

    # Glass panes (2x2 grid)
    d.rectangle([3, 3, 24, 18], fill=WINDOW_SKY)
    d.rectangle([27, 3, 48, 18], fill=WINDOW_SKY)
    d.rectangle([3, 21, 24, 36], fill=(100, 145, 185))  # slightly darker bottom
    d.rectangle([27, 21, 48, 36], fill=(100, 145, 185))

    # Clouds
    d.rectangle([6, 6, 14, 9], fill=(220, 225, 235))
    d.rectangle([32, 8, 42, 11], fill=(220, 225, 235))

    # Curtain edges
    d.rectangle([1, 1, 2, 38], fill=(140, 100, 100))
    d.rectangle([49, 1, 50, 38], fill=(140, 100, 100))

    save(img, 'office', 'window.png')


def make_floor_tile():
    """Floor tile pattern (32x32, tileable)."""
    img = Image.new('RGBA', (32, 32), FLOOR_WOOD + (255,))
    d = ImageDraw.Draw(img)

    # Wood plank lines
    for y in range(0, 32, 8):
        d.rectangle([0, y, 31, y], fill=FLOOR_DARK + (255,))

    # Plank variation
    for x in range(0, 32, 16):
        offset = 4 if (x // 16) % 2 else 0
        for y in range(offset, 32, 8):
            d.rectangle([x + 7, y + 1, x + 8, y + 6], fill=FLOOR_DARK + (80,))

    save(img, 'office', 'floor_tile.png')


def make_rug():
    """Area rug (64x48)."""
    img = Image.new('RGBA', (64, 48), TRANSPARENT)
    d = ImageDraw.Draw(img)

    # Border
    d.rectangle([0, 0, 63, 47], fill=RUG_BORDER + (255,))
    d.rectangle([3, 3, 60, 44], fill=RUG_RED + (255,))
    d.rectangle([6, 6, 57, 41], fill=RUG_BORDER + (255,))
    d.rectangle([8, 8, 55, 39], fill=RUG_RED + (255,))

    # Center pattern
    d.rectangle([24, 18, 39, 29], fill=(140, 55, 50, 255))

    save(img, 'office', 'rug.png')


if __name__ == '__main__':
    print("Generating DFIR Simulator sprites...")
    make_player_spritesheet()
    make_cat()
    make_desk()
    make_bed()
    make_evidence_board()
    make_coffee_station()
    make_phone()
    make_bookshelf()
    make_window()
    make_floor_tile()
    make_rug()
    print("Done! Sprites saved to assets/sprites/")
