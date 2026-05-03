extends RefCounted
class_name DoorSpriteRegistry

## Picks a door sprite from the *destination* location's kind, so every door
## that leads home looks the same, every door into a SITE feels like
## entering a workplace, etc. Keeps tscn instances free of styling decisions.

const LocationDataScript := preload("res://src/systems/world/location_data.gd")

const WOOD: Texture2D = preload("res://assets/sprites/world/doors/wood.png")
const INTERIOR: Texture2D = preload("res://assets/sprites/world/doors/interior.png")
const EXTERIOR: Texture2D = preload("res://assets/sprites/world/doors/exterior.png")


static func sprite_for_target(target_location: StringName) -> Texture2D:
	const LocationsRegistry := preload("res://src/systems/world/locations_registry.gd")
	var loc: Resource = LocationsRegistry.get_location(target_location)
	if loc == null:
		return EXTERIOR
	match int(loc.kind):
		LocationDataScript.Kind.HUB:
			return WOOD
		LocationDataScript.Kind.STREET:
			return EXTERIOR
		LocationDataScript.Kind.SITE:
			return INTERIOR
		LocationDataScript.Kind.HANGOUT:
			return WOOD
	return EXTERIOR
