extends Node
## Owns travel between world locations. Holds the spawn handoff state that
## destination scenes read during their _ready to position the player.

const LocationsRegistry := preload("res://src/systems/world/locations_registry.gd")

signal location_changed(location_id: StringName)
signal location_discovered(location_id: StringName)

var current_location_id: StringName = &""
var pending_spawn_id: StringName = &"default"
var discovered_locations: Array[StringName] = []


func travel_to(location_id: StringName, spawn_id: StringName = &"default") -> void:
	var loc: Resource = LocationsRegistry.get_location(location_id)
	if loc == null:
		push_error("WorldManager: unknown location '%s'" % location_id)
		return
	# Verify the destination scene actually exists *before* we mutate state.
	# Otherwise a typo / parse-error scene leaves current_location_id pointing
	# at a place we never reached.
	if not ResourceLoader.exists(loc.scene_path, "PackedScene"):
		push_error("WorldManager: scene missing for '%s' at %s" % [location_id, loc.scene_path])
		return
	pending_spawn_id = spawn_id
	current_location_id = location_id
	_record_discovery(location_id)
	location_changed.emit(location_id)
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("change_scene"):
		gm.change_scene(loc.scene_path)


func consume_spawn_id() -> StringName:
	## Destination scenes call this in _ready to find their target spawn.
	## We don't reset on read because the scene might re-read during setup.
	return pending_spawn_id


func is_discovered(location_id: StringName) -> bool:
	return discovered_locations.has(location_id)


func get_location(location_id: StringName) -> Resource:
	return LocationsRegistry.get_location(location_id)


func get_discovered_count() -> int:
	return discovered_locations.size()


func get_total_count() -> int:
	return LocationsRegistry.all().size()


func reset() -> void:
	current_location_id = &""
	pending_spawn_id = &"default"
	discovered_locations.clear()


func to_save_dict() -> Dictionary:
	var ids: Array[String] = []
	for d in discovered_locations:
		ids.append(String(d))
	return {
		"current_location_id": String(current_location_id),
		"discovered_locations": ids,
	}


func from_save_dict(data: Dictionary) -> void:
	current_location_id = StringName(str(data.get("current_location_id", "")))
	discovered_locations.clear()
	var ids: Variant = data.get("discovered_locations", [])
	if ids is Array:
		for id in ids:
			discovered_locations.append(StringName(str(id)))


func _record_discovery(location_id: StringName) -> void:
	if discovered_locations.has(location_id):
		return
	discovered_locations.append(location_id)
	location_discovered.emit(location_id)
