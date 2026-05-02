extends "res://src/scenes/components/world_scene.gd"

## First city block. Apartment door on the left, site door on the right, one
## flavor NPC, one secret marker. Proves end-to-end that the framework loop
## works (apartment <-> street <-> site).


func _ready() -> void:
	location_id = &"street_downtown"
	super._ready()
	for child in get_children():
		if child is WorldNPC:
			(child as WorldNPC).dialogue_requested.connect(_on_npc_dialogue)
		if child is SecretMarker:
			(child as SecretMarker).revealed.connect(_on_secret_revealed)


func _on_npc_dialogue(npc: WorldNPC) -> void:
	show_lore_popup(npc.display_name, npc.first_line)


func _on_secret_revealed(marker: SecretMarker) -> void:
	show_lore_popup(marker.display_name, marker.lore_text)
