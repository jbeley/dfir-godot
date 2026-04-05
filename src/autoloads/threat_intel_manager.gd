extends Node
## Loads mirrored threat intelligence data from bundled JSON files.
## No runtime API calls - all data is pre-synced via tools/sync_threat_intel.py.

var cve_entries: Array = []  # Array of Dictionaries
var kev_entries: Array = []  # Array of Dictionaries
var attack_techniques: Dictionary = {}  # technique_id -> Dictionary
var is_loaded: bool = false

signal data_loaded
signal load_failed(reason: String)

const CVE_MIRROR_PATH := "res://assets/data/cve_mirror.json"
const KEV_MIRROR_PATH := "res://assets/data/kev_mirror.json"
const ATTACK_PATH := "res://assets/data/attack_techniques.json"


func _ready() -> void:
	# Defer loading to not block startup
	call_deferred("load_all_data")


func load_all_data() -> void:
	_load_json_file(CVE_MIRROR_PATH, "_on_cve_loaded")
	_load_json_file(KEV_MIRROR_PATH, "_on_kev_loaded")
	_load_json_file(ATTACK_PATH, "_on_attack_loaded")
	is_loaded = true
	data_loaded.emit()


func _load_json_file(path: String, callback: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("Threat intel file not found: %s (will use empty dataset)" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Failed to open: %s" % path)
		return

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	file.close()

	if result != OK:
		push_warning("Failed to parse JSON: %s (line %d)" % [path, json.get_error_line()])
		return

	call(callback, json.data)


func _on_cve_loaded(data: Variant) -> void:
	if data is Array:
		cve_entries = data
	elif data is Dictionary and data.has("vulnerabilities"):
		cve_entries = data["vulnerabilities"]
	print("Loaded %d CVE entries" % cve_entries.size())


func _on_kev_loaded(data: Variant) -> void:
	if data is Array:
		kev_entries = data
	elif data is Dictionary and data.has("vulnerabilities"):
		kev_entries = data["vulnerabilities"]
	print("Loaded %d KEV entries" % kev_entries.size())


func _on_attack_loaded(data: Variant) -> void:
	if data is Dictionary and data.has("techniques"):
		for technique: Dictionary in data["techniques"]:
			var tid: String = technique.get("technique_id", "")
			if tid != "":
				attack_techniques[tid] = technique
	elif data is Array:
		for technique: Dictionary in data:
			var tid: String = technique.get("technique_id", "")
			if tid != "":
				attack_techniques[tid] = technique
	print("Loaded %d ATT&CK techniques" % attack_techniques.size())


func get_random_cve() -> Dictionary:
	if cve_entries.is_empty():
		return {}
	return cve_entries[randi() % cve_entries.size()]


func get_random_kev() -> Dictionary:
	if kev_entries.is_empty():
		return {}
	return kev_entries[randi() % kev_entries.size()]


func get_technique(technique_id: String) -> Dictionary:
	return attack_techniques.get(technique_id, {})


func get_techniques_by_tactic(tactic: String) -> Array:
	var results: Array = []
	for tid in attack_techniques:
		var t: Dictionary = attack_techniques[tid]
		if t.get("tactic", "") == tactic or tactic in t.get("tactics", []):
			results.append(t)
	return results
