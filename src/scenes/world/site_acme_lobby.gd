extends "res://src/scenes/components/world_scene.gd"

## Acme Widget Corp — front lobby. Marcie (recurring) is here. Doors lead
## to the street and to the cube farm. Multi-line dialogue is set in code
## rather than the tscn to keep long lines from tripping the runtime
## resource parser.


func _ready() -> void:
	location_id = &"site_acme_lobby"
	super._ready()
	var marcie: WorldNPC = get_node_or_null("Marcie") as WorldNPC
	if marcie != null:
		marcie.lines = PackedStringArray([
			"You're the consultant? Thank god. I'm Marcie. Twenty-three years here.",
			"Phil from IT has been quiet today. Not productive-quiet. Worth a chat.",
			"We had a cybersecurity awareness training last spring. Pizza was bad. Half the office skipped.",
		])
