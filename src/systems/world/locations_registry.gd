extends RefCounted
class_name LocationsRegistry

## Static registry of every location WorldManager can travel to.
## Keep this dumb — just a lookup table. Faction/case wiring lives elsewhere.

const LocationDataScript := preload("res://src/systems/world/location_data.gd")


static func all() -> Dictionary:
	var out: Dictionary = {}
	out["apartment"] = _make(
		"apartment",
		"Your Apartment",
		"res://src/scenes/office/office.tscn",
		LocationDataScript.Kind.HUB,
		true,
		[]
	)
	out["street_downtown"] = _make(
		"street_downtown",
		"Downtown Block",
		"res://src/scenes/world/street_downtown.tscn",
		LocationDataScript.Kind.STREET,
		true,
		[]
	)
	out["site_shell"] = _make(
		"site_shell",
		"Construction Site",
		"res://src/scenes/world/site_shell.tscn",
		LocationDataScript.Kind.SITE,
		true,
		[]
	)
	return out


static func get_location(id: StringName) -> Resource:
	var registry := all()
	return registry.get(String(id), null)


static func _make(
	id: StringName,
	display_name: String,
	scene_path: String,
	kind: int,
	is_revisitable: bool,
	factions: Array[StringName]
) -> Resource:
	var loc: Resource = LocationDataScript.new()
	loc.id = id
	loc.display_name = display_name
	loc.scene_path = scene_path
	loc.kind = kind
	loc.is_revisitable = is_revisitable
	loc.faction_presence = factions
	return loc
