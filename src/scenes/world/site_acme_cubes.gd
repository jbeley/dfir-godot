extends "res://src/scenes/components/world_scene.gd"

## Acme Widget Corp — open-plan cubicles. Phil from IT is here, panicking.
## Doors lead to lobby, server closet, and back alley.


func _ready() -> void:
	location_id = &"site_acme_cubes"
	super._ready()
