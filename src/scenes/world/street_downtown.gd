extends "res://src/scenes/components/world_scene.gd"

## First city block. Apartment door on the left, site door on the right, one
## flavor NPC, one secret marker. Default WorldScene handlers cover dialogue
## and secret reveals — nothing scene-specific to wire up here.


func _ready() -> void:
	location_id = &"street_downtown"
	super._ready()
