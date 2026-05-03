extends "res://src/scenes/components/world_scene.gd"

## Acme Widget Corp — open-plan cubicles. Phil from IT is here, panicking.
## Doors lead to lobby, server closet, and back alley.


func _ready() -> void:
	location_id = &"site_acme_cubes"
	super._ready()
	var phil: WorldNPC = get_node_or_null("Phil") as WorldNPC
	if phil != null:
		phil.lines = PackedStringArray([
			"I told them. I told them. We needed MFA. Said it was too inconvenient.",
			"The ransom note is on every desktop. Every. Desktop. Backups too.",
			"I run the IT here. Solo. One guy. They want security, hire two more of me.",
		])
