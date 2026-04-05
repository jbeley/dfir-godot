#!/usr/bin/env python3
"""Generate animated cat spritesheet for DFIR Simulator.
States: idle (2 frames), walk (4 frames x 4 dirs), sit, sleep, keyboard, petted
Layout: 16x12 per frame, arranged in rows by state.
"""

from PIL import Image, ImageDraw
import os

W, H = 16, 14
SPRITES_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sprites')

# Colors
ORANGE = (210, 150, 60)
DARK = (170, 110, 40)
WHITE = (240, 235, 225)
NOSE = (200, 130, 130)
EYE_OPEN = (80, 160, 80)
EYE_CLOSED = (170, 110, 40)
TAIL = (180, 120, 45)
PAW = (220, 170, 90)
HEART = (220, 80, 80)


def draw_cat_base(d, x_off=0, y_off=0, facing="right", eyes="open", tail_up=False):
    """Draw base cat shape."""
    xo, yo = x_off, y_off

    if facing == "right":
        # Body
        d.rectangle([3+xo, 5+yo, 12+xo, 10+yo], fill=ORANGE)
        d.rectangle([4+xo, 4+yo, 11+xo, 5+yo], fill=ORANGE)
        # Head
        d.rectangle([1+xo, 3+yo, 5+xo, 7+yo], fill=ORANGE)
        # Ears
        d.point((1+xo, 2+yo), fill=DARK)
        d.point((5+xo, 2+yo), fill=DARK)
        # Eyes
        eye_color = EYE_OPEN if eyes == "open" else EYE_CLOSED
        d.point((2+xo, 4+yo), fill=eye_color)
        d.point((4+xo, 4+yo), fill=eye_color)
        # Nose
        d.point((3+xo, 5+yo), fill=NOSE)
        # Stripes
        d.point((6+xo, 4+yo), fill=DARK)
        d.point((8+xo, 4+yo), fill=DARK)
        d.point((10+xo, 4+yo), fill=DARK)
        # Belly
        d.rectangle([5+xo, 8+yo, 10+xo, 9+yo], fill=WHITE)
        # Tail
        if tail_up:
            d.rectangle([12+xo, 2+yo, 13+xo, 5+yo], fill=TAIL)
            d.point((14+xo, 1+yo), fill=TAIL)
        else:
            d.rectangle([12+xo, 3+yo, 14+xo, 4+yo], fill=TAIL)
            d.point((15+xo, 2+yo), fill=TAIL)
    else:  # left
        # Body
        d.rectangle([3+xo, 5+yo, 12+xo, 10+yo], fill=ORANGE)
        d.rectangle([4+xo, 4+yo, 11+xo, 5+yo], fill=ORANGE)
        # Head
        d.rectangle([10+xo, 3+yo, 14+xo, 7+yo], fill=ORANGE)
        # Ears
        d.point((10+xo, 2+yo), fill=DARK)
        d.point((14+xo, 2+yo), fill=DARK)
        # Eyes
        eye_color = EYE_OPEN if eyes == "open" else EYE_CLOSED
        d.point((11+xo, 4+yo), fill=eye_color)
        d.point((13+xo, 4+yo), fill=eye_color)
        # Nose
        d.point((12+xo, 5+yo), fill=NOSE)
        # Stripes
        d.point((5+xo, 4+yo), fill=DARK)
        d.point((7+xo, 4+yo), fill=DARK)
        d.point((9+xo, 4+yo), fill=DARK)
        # Belly
        d.rectangle([5+xo, 8+yo, 10+xo, 9+yo], fill=WHITE)
        # Tail
        if tail_up:
            d.rectangle([1+xo, 2+yo, 2+xo, 5+yo], fill=TAIL)
            d.point((0+xo, 1+yo), fill=TAIL)
        else:
            d.rectangle([0+xo, 3+yo, 2+xo, 4+yo], fill=TAIL)


def make_frame():
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def idle_frames():
    """2 frames: tail swish."""
    frames = []
    for i in range(2):
        img, d = make_frame()
        draw_cat_base(d, facing="right", tail_up=(i == 1))
        # Legs
        d.rectangle([4, 11, 5, 13], fill=ORANGE)
        d.rectangle([10, 11, 11, 13], fill=ORANGE)
        frames.append(img)
    return frames


def walk_right_frames():
    """4 walk frames facing right."""
    frames = []
    for i in range(4):
        img, d = make_frame()
        bob = 1 if i % 2 else 0
        draw_cat_base(d, y_off=bob, facing="right", tail_up=(i in [1, 2]))
        # Walk legs
        if i == 0:
            d.rectangle([4, 11+bob, 5, 13], fill=ORANGE)
            d.rectangle([10, 11+bob, 11, 13], fill=ORANGE)
        elif i == 1:
            d.rectangle([3, 11+bob, 4, 13], fill=ORANGE)
            d.rectangle([11, 10+bob, 12, 13], fill=ORANGE)
        elif i == 2:
            d.rectangle([4, 11+bob, 5, 13], fill=ORANGE)
            d.rectangle([10, 11+bob, 11, 13], fill=ORANGE)
        else:
            d.rectangle([5, 10+bob, 6, 13], fill=ORANGE)
            d.rectangle([9, 11+bob, 10, 13], fill=ORANGE)
        frames.append(img)
    return frames


def walk_left_frames():
    """4 walk frames facing left."""
    frames = []
    for i in range(4):
        img, d = make_frame()
        bob = 1 if i % 2 else 0
        draw_cat_base(d, y_off=bob, facing="left", tail_up=(i in [1, 2]))
        if i == 0:
            d.rectangle([4, 11+bob, 5, 13], fill=ORANGE)
            d.rectangle([10, 11+bob, 11, 13], fill=ORANGE)
        elif i == 1:
            d.rectangle([3, 10+bob, 4, 13], fill=ORANGE)
            d.rectangle([11, 11+bob, 12, 13], fill=ORANGE)
        elif i == 2:
            d.rectangle([4, 11+bob, 5, 13], fill=ORANGE)
            d.rectangle([10, 11+bob, 11, 13], fill=ORANGE)
        else:
            d.rectangle([5, 11+bob, 6, 13], fill=ORANGE)
            d.rectangle([9, 10+bob, 10, 13], fill=ORANGE)
        frames.append(img)
    return frames


def sleep_frames():
    """2 frames: breathing while sleeping (curled up)."""
    frames = []
    for i in range(2):
        img, d = make_frame()
        # Curled up cat body
        y = 6 if i == 0 else 5
        d.rectangle([3, y, 12, y+5], fill=ORANGE)
        d.rectangle([4, y-1, 11, y], fill=ORANGE)
        # Head tucked
        d.rectangle([2, y+1, 5, y+4], fill=ORANGE)
        d.point((2, y), fill=DARK)  # ear
        d.point((5, y), fill=DARK)  # ear
        # Closed eyes
        d.point((3, y+2), fill=EYE_CLOSED)
        # Tail wrapped around
        d.rectangle([10, y-1, 13, y], fill=TAIL)
        # Belly
        d.rectangle([5, y+3, 9, y+4], fill=WHITE)
        # Zzz
        if i == 1:
            d.point((7, y-2), fill=(200, 200, 255))
            d.point((9, y-3), fill=(180, 180, 235))
        frames.append(img)
    return frames


def keyboard_frames():
    """2 frames: cat sitting on keyboard, paws tapping."""
    frames = []
    for i in range(2):
        img, d = make_frame()
        # Keyboard below cat
        d.rectangle([1, 10, 14, 13], fill=(130, 135, 145))
        d.rectangle([2, 11, 13, 12], fill=(110, 115, 125))
        # Cat sitting on it
        draw_cat_base(d, y_off=-2, facing="right", eyes="open", tail_up=True)
        # Paws on keys
        paw_x = 6 if i == 0 else 8
        d.rectangle([paw_x, 8, paw_x+2, 9], fill=PAW)
        # Legs tucked
        d.rectangle([4, 9, 5, 10], fill=ORANGE)
        d.rectangle([10, 9, 11, 10], fill=ORANGE)
        frames.append(img)
    return frames


def petted_frames():
    """3 frames: being petted, hearts."""
    frames = []
    for i in range(3):
        img, d = make_frame()
        draw_cat_base(d, facing="right", eyes="closed" if i == 1 else "open", tail_up=True)
        # Legs
        d.rectangle([4, 11, 5, 13], fill=ORANGE)
        d.rectangle([10, 11, 11, 13], fill=ORANGE)
        # Hearts floating up
        if i >= 1:
            d.point((3, 0), fill=HEART)
            d.point((2, 1), fill=HEART)
            d.point((4, 1), fill=HEART)
        if i >= 2:
            d.point((8, 1), fill=HEART)
            d.point((7, 2), fill=HEART)
            d.point((9, 2), fill=HEART)
        frames.append(img)
    return frames


def main():
    # Layout: each state is a row
    # Row 0: idle (2 frames)
    # Row 1: walk right (4 frames)
    # Row 2: walk left (4 frames)
    # Row 3: sleep (2 frames)
    # Row 4: keyboard (2 frames)
    # Row 5: petted (3 frames)
    COLS = 4  # max frames per row
    ROWS = 6
    sheet = Image.new('RGBA', (W * COLS, H * ROWS), (0, 0, 0, 0))

    all_rows = [
        idle_frames(),
        walk_right_frames(),
        walk_left_frames(),
        sleep_frames(),
        keyboard_frames(),
        petted_frames(),
    ]

    for row, frames in enumerate(all_rows):
        for col, frame in enumerate(frames):
            sheet.paste(frame, (col * W, row * H))

    os.makedirs(os.path.join(SPRITES_DIR, 'characters'), exist_ok=True)
    path = os.path.join(SPRITES_DIR, 'characters', 'cat_animated.png')
    sheet.save(path)
    print(f"Cat spritesheet saved: {path}")
    print(f"  Size: {sheet.size[0]}x{sheet.size[1]} ({COLS} cols x {ROWS} rows)")
    print(f"  Frame size: {W}x{H}")
    print(f"  States: idle(2), walk_r(4), walk_l(4), sleep(2), keyboard(2), petted(3)")


if __name__ == '__main__':
    main()
