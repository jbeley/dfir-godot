extends RefCounted
class_name NpcSpriteRegistry

## Lookup of pixel-art NPC sprites by npc_id. Keeps WorldNPC instances dumb —
## the .tscn doesn't need a sprite_texture set; the component pulls its
## texture from here on _ready, falling back to the placeholder rect if no
## sprite is registered for the id.

const SPRITES: Dictionary = {
	&"marcie_rivera": preload("res://assets/sprites/world/npcs/marcie_rivera.png"),
	&"asha_patel": preload("res://assets/sprites/world/npcs/asha_patel.png"),
	&"street_busker": preload("res://assets/sprites/world/npcs/street_busker.png"),
	&"phil_garcia": preload("res://assets/sprites/world/npcs/phil_garcia.png"),
	&"shawn_it": preload("res://assets/sprites/world/npcs/shawn_it.png"),
	&"alley_janitor": preload("res://assets/sprites/world/npcs/alley_janitor.png"),
	&"hospital_chaplain": preload("res://assets/sprites/world/npcs/hospital_chaplain.png"),
	&"darklock_mike": preload("res://assets/sprites/world/npcs/darklock_mike.png"),
	&"darklock_devon": preload("res://assets/sprites/world/npcs/darklock_devon.png"),
}


static func get_sprite(npc_id: StringName) -> Texture2D:
	return SPRITES.get(npc_id, null)
