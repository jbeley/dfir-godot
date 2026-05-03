#!/usr/bin/env python3
"""Generate per-character NPC sprites + door sprites for the walkable city.
Reuses the player palette; each NPC gets a distinct hair / shirt combo so
players recognize them at a glance.

Run from repo root: python3 tools/generate_world_sprites.py
Outputs to assets/sprites/world/{npcs,doors}/.
"""

from __future__ import annotations

import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "world")
TRANSPARENT = (0, 0, 0, 0)

SKIN_LIGHT = (235, 200, 165)
SKIN_TAN = (210, 170, 130)
SKIN_DARK = (160, 115, 80)

# Each NPC: hair, shirt, pants, skin
NPCS = {
    # Recurring named characters
    "marcie_rivera": (( 90,  60,  40), (140,  60,  90), ( 50,  45,  55), SKIN_LIGHT),
    "asha_patel":    (( 30,  25,  20), (200, 230, 240), ( 40,  60,  90), SKIN_DARK),
    # Flavor NPCs
    "street_busker": ((180, 140,  80), (130, 110,  60), ( 80,  60,  50), SKIN_TAN),
    "phil_garcia":   (( 60,  45,  30), ( 70, 130,  80), ( 50,  50,  60), SKIN_TAN),
    "shawn_it":      ((100,  80, 130), ( 30,  40,  60), ( 35,  35,  45), SKIN_LIGHT),
    # Secret NPCs
    "alley_janitor":    ((180, 180, 180), ( 50,  90, 130), ( 50,  50,  60), SKIN_TAN),
    "hospital_chaplain": (( 40,  40,  40), ( 30,  30,  35), ( 30,  30,  35), SKIN_LIGHT),
    # Faction recruiters
    "darklock_mike":  (( 30,  30,  30), ( 40,  40,  45), ( 30,  30,  35), SKIN_LIGHT),
    "darklock_devon": (( 35,  35,  35), ( 70,  20,  20), ( 30,  30,  35), SKIN_TAN),
}


def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def npc_sprite(hair: tuple, shirt: tuple, pants: tuple, skin: tuple) -> Image.Image:
    """Return a 16x20 down-facing standing pose. Same proportions as the
    player so silhouettes feel consistent in the city."""
    img = Image.new("RGBA", (16, 20), TRANSPARENT)
    d = ImageDraw.Draw(img)
    # Hair
    d.rectangle([5, 1, 10, 4], fill=hair)
    # Head
    d.rectangle([5, 3, 10, 7], fill=skin)
    # Eyes (down-facing)
    d.point((6, 5), fill=(40, 40, 50))
    d.point((9, 5), fill=(40, 40, 50))
    # Shirt
    d.rectangle([4, 8, 11, 13], fill=shirt)
    # Arms
    d.rectangle([3, 9, 3, 12], fill=shirt)
    d.rectangle([12, 9, 12, 12], fill=shirt)
    # Pants
    d.rectangle([5, 14, 10, 17], fill=pants)
    # Shoes
    d.rectangle([5, 18, 7, 19], fill=(40, 30, 25))
    d.rectangle([8, 18, 10, 19], fill=(40, 30, 25))
    # Subtle outline at the waist for legibility against pale floors
    d.point((4, 14), fill=(20, 20, 25, 180))
    d.point((11, 14), fill=(20, 20, 25, 180))
    return img


def door_sprite(panel: tuple, frame: tuple, knob: tuple) -> Image.Image:
    """Return a 24x28 door-facing-the-camera sprite — frame, panel, knob."""
    img = Image.new("RGBA", (24, 28), TRANSPARENT)
    d = ImageDraw.Draw(img)
    # Frame
    d.rectangle([0, 0, 23, 27], fill=frame)
    # Panel
    d.rectangle([2, 3, 21, 26], fill=panel)
    # Inset detail
    d.rectangle([4, 5, 19, 14], outline=frame)
    d.rectangle([4, 16, 19, 24], outline=frame)
    # Knob
    d.ellipse([16, 18, 19, 21], fill=knob)
    # Welcome scuff
    d.point((11, 26), fill=(30, 30, 30))
    d.point((12, 26), fill=(30, 30, 30))
    return img


def secret_marker_sprite() -> Image.Image:
    """Subtle dotted question mark — only the *outline* is rendered, kept
    very faint so it doesn't spoil the secret. Use sparingly; most secrets
    should still rely on environmental cues alone."""
    img = Image.new("RGBA", (12, 12), TRANSPARENT)
    d = ImageDraw.Draw(img)
    # Faint glow square — barely visible
    d.rectangle([0, 0, 11, 11], outline=(255, 255, 220, 35))
    return img


def main() -> None:
    npc_dir = os.path.join(OUT, "npcs")
    door_dir = os.path.join(OUT, "doors")
    ensure_dir(npc_dir)
    ensure_dir(door_dir)

    print("== NPC sprites ==")
    for npc_id, (hair, shirt, pants, skin) in NPCS.items():
        img = npc_sprite(hair, shirt, pants, skin)
        path = os.path.join(npc_dir, f"{npc_id}.png")
        img.save(path)
        print(f"  {path}")

    print("== Door sprites ==")
    doors = {
        # warm wooden door for residential / hub locations
        "wood":     ((140, 100,  60), ( 70,  50,  30), (210, 180,  60)),
        # corporate beige for office/clinic interiors
        "interior": ((180, 180, 175), (110, 110, 105), (100, 100, 100)),
        # exterior steel for service / alley exits
        "exterior": (( 80,  90, 100), ( 35,  45,  55), (170, 170, 170)),
    }
    for name, (panel, frame, knob) in doors.items():
        img = door_sprite(panel, frame, knob)
        path = os.path.join(door_dir, f"{name}.png")
        img.save(path)
        print(f"  {path}")

    print("== Secret marker sprite ==")
    img = secret_marker_sprite()
    path = os.path.join(OUT, "secret_marker.png")
    img.save(path)
    print(f"  {path}")


if __name__ == "__main__":
    main()
