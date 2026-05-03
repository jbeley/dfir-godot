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
	var darklock: Array[StringName] = [&"darklock"]
	out["site_acme_lobby"] = _make(
		"site_acme_lobby",
		"Acme Widget Corp - Lobby",
		"res://src/scenes/world/site_acme_lobby.tscn",
		LocationDataScript.Kind.SITE,
		true,
		darklock
	)
	out["site_acme_cubes"] = _make(
		"site_acme_cubes",
		"Acme Widget Corp - Operations",
		"res://src/scenes/world/site_acme_cubes.tscn",
		LocationDataScript.Kind.SITE,
		true,
		darklock
	)
	out["site_acme_server"] = _make(
		"site_acme_server",
		"Acme Widget Corp - Server Closet",
		"res://src/scenes/world/site_acme_server.tscn",
		LocationDataScript.Kind.SITE,
		true,
		darklock
	)
	out["site_acme_alley"] = _make(
		"site_acme_alley",
		"Acme Widget Corp - Back Alley",
		"res://src/scenes/world/site_acme_alley.tscn",
		LocationDataScript.Kind.SITE,
		true,
		darklock
	)
	out["site_hospital_lobby"] = _make(
		"site_hospital_lobby",
		"St. Catherine's - Lobby",
		"res://src/scenes/world/site_hospital_lobby.tscn",
		LocationDataScript.Kind.SITE,
		true,
		darklock
	)
	out["site_hospital_nurse"] = _make(
		"site_hospital_nurse",
		"St. Catherine's - Wards",
		"res://src/scenes/world/site_hospital_nurse.tscn",
		LocationDataScript.Kind.SITE,
		true,
		darklock
	)
	out["site_hospital_server"] = _make(
		"site_hospital_server",
		"St. Catherine's - IT Room",
		"res://src/scenes/world/site_hospital_server.tscn",
		LocationDataScript.Kind.SITE,
		true,
		darklock
	)
	out["site_hospital_parking"] = _make(
		"site_hospital_parking",
		"St. Catherine's - Parking Lot",
		"res://src/scenes/world/site_hospital_parking.tscn",
		LocationDataScript.Kind.SITE,
		true,
		darklock
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
