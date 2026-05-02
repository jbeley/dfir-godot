extends "res://src/scenes/components/world_scene.gd"

## Acme Widget Corp — back alley. Three of the slice's anchor moments live
## here: the secret-NPC janitor, a DarkLock affiliate trying to recruit you,
## and a parked white van that raises DarkLock heat the first time you spot it.
## Defaults handle dialogue/secret/surveillance dispatch.


func _ready() -> void:
	location_id = &"site_acme_alley"
	super._ready()
	var janitor: WorldNPC = get_node_or_null("Janitor") as WorldNPC
	if janitor != null:
		janitor.lines = PackedStringArray([
			"Thirty-one years on this dock. I take out the trash. I see things every day.",
			"That van has been parked there since Monday. Same plate. They never unload anything.",
			"I'm not paid to ask. But if I were a younger man, I would ask.",
		])
	var mike: WorldNPC = get_node_or_null("Mike") as WorldNPC
	if mike != null:
		mike.lines = PackedStringArray([
			"You're the consultant. I do contract work. Some of it is for the other side of incidents like this. Good money in being slow.",
			"If your timeline grading comes in late, certain people would be grateful. Anonymous.",
			"Suit yourself. You know where to find me. Or you don't.",
		])
