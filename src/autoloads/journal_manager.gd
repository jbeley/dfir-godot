extends Node
## Post-hoc tracker. Records what the player has *already found*. Never lists
## what they haven't yet — secrets stay pure-hidden until discovered.

signal location_visited(location_id: StringName)
signal npc_met(npc_id: StringName)
signal secret_found(secret_id: StringName)
signal rumor_heard(rumor_id: StringName)
signal faction_interaction(faction_id: StringName, delta: int)

var _locations_visited: Dictionary = {}  # StringName -> int (visit count)
var _npcs_met: Dictionary = {}  # StringName -> Dictionary{display_name, archetype, last_line}
var _secrets_found: Dictionary = {}  # StringName -> Dictionary{display_name, lore_text}
var _rumors_heard: Dictionary = {}  # StringName -> String (rumor text)
var _faction_standing: Dictionary = {}  # StringName -> int

# Set of registered secret ids. Internal — never exposed, only its size is.
# Using a set so a SecretMarker that re-runs _ready (scene revisit) doesn't
# inflate the denominator for the journal's "X of Y found" counter.
var _registered_secret_ids: Dictionary = {}


func record_location_visited(location_id: StringName) -> void:
	if location_id == &"":
		return
	var prev: int = int(_locations_visited.get(location_id, 0))
	_locations_visited[location_id] = prev + 1
	location_visited.emit(location_id)


func record_npc_met(
	npc_id: StringName, display_name: String, archetype: String, last_line: String = ""
) -> void:
	if npc_id == &"":
		return
	_npcs_met[npc_id] = {
		"display_name": display_name,
		"archetype": archetype,
		"last_line": last_line,
	}
	npc_met.emit(npc_id)


func record_secret_found(secret_id: StringName, display_name: String, lore_text: String) -> void:
	if secret_id == &"" or _secrets_found.has(secret_id):
		return
	_secrets_found[secret_id] = {
		"display_name": display_name,
		"lore_text": lore_text,
	}
	secret_found.emit(secret_id)


func record_rumor_heard(rumor_id: StringName, text: String) -> void:
	if rumor_id == &"" or _rumors_heard.has(rumor_id):
		return
	_rumors_heard[rumor_id] = text
	rumor_heard.emit(rumor_id)


func record_faction_interaction(faction_id: StringName, delta: int) -> void:
	if faction_id == &"":
		return
	var prev: int = int(_faction_standing.get(faction_id, 0))
	_faction_standing[faction_id] = prev + delta
	faction_interaction.emit(faction_id, delta)


func register_secret(secret_id: StringName) -> void:
	## Scenes call this for each placed secret marker so the counter denominator
	## reflects what's actually findable. Idempotent — re-registering the same
	## id on scene revisit is a no-op, and the journal never exposes the ids
	## of unfound secrets.
	if secret_id == &"":
		return
	_registered_secret_ids[secret_id] = true


func get_secrets_found_count() -> int:
	return _secrets_found.size()


func get_secrets_known_count() -> int:
	return _registered_secret_ids.size()


func get_locations_visited() -> Dictionary:
	return _locations_visited.duplicate(true)


func get_npcs_met() -> Dictionary:
	return _npcs_met.duplicate(true)


func get_secrets_found() -> Dictionary:
	return _secrets_found.duplicate(true)


func get_rumors_heard() -> Dictionary:
	return _rumors_heard.duplicate(true)


func get_faction_standing(faction_id: StringName) -> int:
	return int(_faction_standing.get(faction_id, 0))


func get_all_faction_standings() -> Dictionary:
	return _faction_standing.duplicate(true)


func has_met_npc(npc_id: StringName) -> bool:
	return _npcs_met.has(npc_id)


func has_found_secret(secret_id: StringName) -> bool:
	return _secrets_found.has(secret_id)


func reset() -> void:
	_locations_visited.clear()
	_npcs_met.clear()
	_secrets_found.clear()
	_rumors_heard.clear()
	_faction_standing.clear()
	_registered_secret_ids.clear()


func to_save_dict() -> Dictionary:
	return {
		"locations_visited": _stringify_keys(_locations_visited),
		"npcs_met": _stringify_keys(_npcs_met),
		"secrets_found": _stringify_keys(_secrets_found),
		"rumors_heard": _stringify_keys(_rumors_heard),
		"faction_standing": _stringify_keys(_faction_standing),
	}


func from_save_dict(data: Dictionary) -> void:
	reset()
	_locations_visited = _restore_int_dict(data.get("locations_visited", {}))
	_npcs_met = _restore_dict_of_dicts(data.get("npcs_met", {}))
	_secrets_found = _restore_dict_of_dicts(data.get("secrets_found", {}))
	_rumors_heard = _restore_string_dict(data.get("rumors_heard", {}))
	_faction_standing = _restore_int_dict(data.get("faction_standing", {}))


func _stringify_keys(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k: Variant in d:
		out[String(k)] = d[k]
	return out


func _restore_int_dict(v: Variant) -> Dictionary:
	var out: Dictionary = {}
	if v is Dictionary:
		for k: Variant in v:
			out[StringName(str(k))] = int(v[k])
	return out


func _restore_string_dict(v: Variant) -> Dictionary:
	var out: Dictionary = {}
	if v is Dictionary:
		for k: Variant in v:
			out[StringName(str(k))] = str(v[k])
	return out


func _restore_dict_of_dicts(v: Variant) -> Dictionary:
	var out: Dictionary = {}
	if v is Dictionary:
		for k: Variant in v:
			var entry: Variant = v[k]
			if entry is Dictionary:
				out[StringName(str(k))] = (entry as Dictionary).duplicate(true)
	return out
