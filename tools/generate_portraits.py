#!/usr/bin/env python3
"""Generate pixel art NPC portraits for DFIR Simulator.
32x32 face portraits for dialogue scenes.
"""

from PIL import Image, ImageDraw
import os

W, H = 32, 32
SPRITES_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sprites')
TRANSPARENT = (0, 0, 0, 0)


def save(img, name):
    path = os.path.join(SPRITES_DIR, 'characters', 'portraits', name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  {name}")


def draw_head(d, skin, hair_color, hair_style="short", shirt_color=(60, 90, 140),
              eyes=(40, 40, 50), has_glasses=False, has_beard=False, expression="neutral"):
    """Draw a face portrait."""
    # Neck/shirt
    d.rectangle([10, 24, 21, 31], fill=shirt_color)
    d.rectangle([8, 27, 23, 31], fill=shirt_color)
    # Collar
    d.rectangle([12, 24, 19, 25], fill=skin)

    # Head shape
    d.rectangle([8, 6, 23, 23], fill=skin)
    d.rectangle([9, 5, 22, 6], fill=skin)
    d.rectangle([10, 4, 21, 5], fill=skin)

    # Hair
    if hair_style == "short":
        d.rectangle([8, 3, 23, 8], fill=hair_color)
        d.rectangle([7, 5, 8, 10], fill=hair_color)
        d.rectangle([23, 5, 24, 10], fill=hair_color)
    elif hair_style == "bald":
        d.rectangle([9, 3, 22, 5], fill=hair_color)
    elif hair_style == "long":
        d.rectangle([7, 3, 24, 9], fill=hair_color)
        d.rectangle([6, 6, 8, 20], fill=hair_color)
        d.rectangle([23, 6, 25, 20], fill=hair_color)
    elif hair_style == "buzz":
        d.rectangle([8, 3, 23, 7], fill=hair_color)
    elif hair_style == "parted":
        d.rectangle([8, 3, 23, 8], fill=hair_color)
        d.rectangle([14, 3, 16, 5], fill=skin)  # Part

    # Ears
    d.rectangle([6, 12, 8, 17], fill=skin)
    d.rectangle([23, 12, 25, 17], fill=skin)

    # Eyes
    eye_y = 13
    if expression == "panicked":
        # Wide eyes
        d.rectangle([11, eye_y-1, 14, eye_y+2], fill=(240, 240, 245))
        d.rectangle([17, eye_y-1, 20, eye_y+2], fill=(240, 240, 245))
        d.rectangle([12, eye_y, 13, eye_y+1], fill=eyes)
        d.rectangle([18, eye_y, 19, eye_y+1], fill=eyes)
    elif expression == "stern":
        d.rectangle([11, eye_y, 14, eye_y+1], fill=(240, 240, 245))
        d.rectangle([17, eye_y, 20, eye_y+1], fill=(240, 240, 245))
        d.rectangle([12, eye_y, 13, eye_y], fill=eyes)
        d.rectangle([18, eye_y, 19, eye_y], fill=eyes)
        # Furrowed brows
        d.rectangle([10, eye_y-2, 14, eye_y-1], fill=hair_color)
        d.rectangle([17, eye_y-2, 21, eye_y-1], fill=hair_color)
    elif expression == "tired":
        d.rectangle([11, eye_y, 14, eye_y+1], fill=(240, 240, 245))
        d.rectangle([17, eye_y, 20, eye_y+1], fill=(240, 240, 245))
        d.rectangle([12, eye_y, 13, eye_y], fill=eyes)
        d.rectangle([18, eye_y, 19, eye_y], fill=eyes)
        # Bags under eyes
        d.rectangle([11, eye_y+2, 14, eye_y+2], fill=(skin[0]-20, skin[1]-20, skin[2]-10))
        d.rectangle([17, eye_y+2, 20, eye_y+2], fill=(skin[0]-20, skin[1]-20, skin[2]-10))
    elif expression == "smug":
        d.rectangle([11, eye_y, 14, eye_y+1], fill=(240, 240, 245))
        d.rectangle([17, eye_y, 20, eye_y+1], fill=(240, 240, 245))
        d.rectangle([13, eye_y, 14, eye_y], fill=eyes)
        d.rectangle([17, eye_y, 18, eye_y], fill=eyes)
        # Raised eyebrow
        d.rectangle([17, eye_y-2, 21, eye_y-2], fill=hair_color)
        d.rectangle([10, eye_y-1, 14, eye_y-1], fill=hair_color)
    else:  # neutral
        d.rectangle([11, eye_y, 14, eye_y+1], fill=(240, 240, 245))
        d.rectangle([17, eye_y, 20, eye_y+1], fill=(240, 240, 245))
        d.rectangle([12, eye_y, 13, eye_y], fill=eyes)
        d.rectangle([18, eye_y, 19, eye_y], fill=eyes)

    # Glasses
    if has_glasses:
        d.rectangle([10, eye_y-1, 15, eye_y+2], fill=None, outline=(60, 60, 70))
        d.rectangle([16, eye_y-1, 21, eye_y+2], fill=None, outline=(60, 60, 70))
        d.rectangle([15, eye_y, 16, eye_y], fill=(60, 60, 70))

    # Nose
    d.rectangle([15, 16, 16, 18], fill=(skin[0]-15, skin[1]-15, skin[2]-10))

    # Mouth
    if expression == "panicked":
        d.rectangle([13, 20, 18, 21], fill=(180, 100, 100))  # Open mouth
    elif expression == "stern":
        d.rectangle([13, 20, 18, 20], fill=(skin[0]-30, skin[1]-30, skin[2]-20))  # Thin line
    elif expression == "smug":
        d.rectangle([14, 20, 18, 20], fill=(skin[0]-20, skin[1]-20, skin[2]-15))
        d.point((18, 19), fill=(skin[0]-20, skin[1]-20, skin[2]-15))  # Smirk
    else:
        d.rectangle([13, 20, 18, 20], fill=(skin[0]-20, skin[1]-20, skin[2]-15))

    # Beard
    if has_beard:
        d.rectangle([9, 18, 22, 23], fill=hair_color)
        d.rectangle([10, 17, 21, 18], fill=hair_color)
        # Re-draw mouth over beard
        d.rectangle([13, 20, 18, 20], fill=(skin[0]-20, skin[1]-20, skin[2]-15))


def make_portrait(name, **kwargs):
    img = Image.new('RGBA', (W, H), TRANSPARENT)
    d = ImageDraw.Draw(img)
    draw_head(d, **kwargs)
    save(img, name)


def main():
    print("Generating NPC portraits...")

    SKIN_LIGHT = (235, 200, 165)
    SKIN_MED = (200, 160, 120)
    SKIN_DARK = (160, 110, 70)
    SKIN_OLIVE = (210, 180, 140)

    # Panicked CEO - Dave Morrison
    make_portrait("panicked_ceo.png",
        skin=SKIN_LIGHT, hair_color=(60, 45, 30), hair_style="parted",
        shirt_color=(50, 50, 65), expression="panicked", has_glasses=False)

    # Lone IT Admin - Mike
    make_portrait("it_admin.png",
        skin=SKIN_LIGHT, hair_color=(80, 60, 40), hair_style="buzz",
        shirt_color=(40, 80, 40), expression="tired", has_glasses=True, has_beard=True)

    # Hostile Lawyer
    make_portrait("hostile_lawyer.png",
        skin=SKIN_MED, hair_color=(30, 25, 20), hair_style="short",
        shirt_color=(40, 40, 50), expression="stern", has_glasses=True)

    # Competent CISO
    make_portrait("competent_ciso.png",
        skin=SKIN_DARK, hair_color=(20, 15, 10), hair_style="short",
        shirt_color=(50, 50, 80), expression="neutral", has_glasses=False)

    # IT Hero
    make_portrait("it_hero.png",
        skin=SKIN_OLIVE, hair_color=(40, 30, 20), hair_style="short",
        shirt_color=(100, 40, 40), expression="tired", has_glasses=False)

    # Mentor / Senior Analyst
    make_portrait("mentor.png",
        skin=SKIN_MED, hair_color=(120, 120, 130), hair_style="short",
        shirt_color=(50, 60, 80), expression="neutral", has_glasses=True, has_beard=True)

    # Player (you)
    make_portrait("player_portrait.png",
        skin=SKIN_LIGHT, hair_color=(50, 35, 25), hair_style="short",
        shirt_color=(60, 90, 140), expression="neutral")

    # FBI Agent
    make_portrait("fbi_agent.png",
        skin=SKIN_DARK, hair_color=(15, 10, 5), hair_style="buzz",
        shirt_color=(30, 30, 40), expression="stern")

    # Ransomware operator (shadowy)
    img = Image.new('RGBA', (W, H), TRANSPARENT)
    d = ImageDraw.Draw(img)
    # Dark silhouette with hoodie
    d.rectangle([8, 6, 23, 23], fill=(30, 30, 35))
    d.rectangle([6, 3, 25, 12], fill=(25, 25, 30))  # Hood
    d.rectangle([10, 24, 21, 31], fill=(25, 25, 30))
    d.rectangle([8, 27, 23, 31], fill=(25, 25, 30))
    # Glowing eyes
    d.rectangle([12, 13, 13, 14], fill=(0, 255, 0))
    d.rectangle([18, 13, 19, 14], fill=(0, 255, 0))
    # Screen reflection
    d.rectangle([11, 18, 20, 19], fill=(0, 60, 0))
    save(img, "threat_actor.png")

    print("Done! 9 portraits generated.")


if __name__ == '__main__':
    main()
