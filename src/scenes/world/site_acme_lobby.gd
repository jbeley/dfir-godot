extends "res://src/scenes/components/world_scene.gd"

## Acme Widget Corp — front lobby. Marcie (recurring) is here. Doors lead
## to the street and to the cube farm.


func _ready() -> void:
	location_id = &"site_acme_lobby"
	super._ready()
