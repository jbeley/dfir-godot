extends Resource
class_name LocationData

## A registered place in the world. Drive WorldManager.travel_to via these.

enum Kind {
	HUB,  # Apartment / your home base.
	STREET,  # Walkable connector between locations.
	SITE,  # Client site or other destination building.
	HANGOUT,  # Persistent social location (coffee shop, hackerspace).
}

@export var id: StringName
@export var display_name: String = ""
@export var scene_path: String = ""
@export var kind: Kind = Kind.SITE
@export var is_revisitable: bool = true
@export var faction_presence: Array[StringName] = []
