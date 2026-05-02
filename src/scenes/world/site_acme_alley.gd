extends "res://src/scenes/components/world_scene.gd"

## Acme Widget Corp — back alley. Three of the slice's anchor moments live
## here: the secret-NPC janitor, a DarkLock affiliate trying to recruit you,
## and a parked white van that raises DarkLock heat the first time you spot it.
## Defaults handle dialogue/secret/surveillance dispatch.


func _ready() -> void:
	location_id = &"site_acme_alley"
	super._ready()
