extends Node
## Per-faction surveillance heat. Skeleton for the surveillance subsystem —
## content (white van moments, tail encounters) plugs in via signals later.

const DECAY_PER_HOUR: float = 1.0
const MAX_HEAT: float = 100.0
const THRESHOLD_NOTICED: float = 25.0
const THRESHOLD_HOSTILE: float = 60.0

signal heat_changed(faction_id: StringName, heat: float)
signal heat_threshold_crossed(faction_id: StringName, threshold: float)

var _heat: Dictionary = {}  # StringName -> float
var _last_threshold: Dictionary = {}  # StringName -> float (highest crossed)


func _ready() -> void:
	if Engine.has_singleton("TimeManager") or has_node("/root/TimeManager"):
		var tm: Node = get_node_or_null("/root/TimeManager")
		if tm and tm.has_signal("hour_changed"):
			tm.hour_changed.connect(_on_hour_changed)


func add_heat(faction_id: StringName, amount: float) -> void:
	if faction_id == &"":
		return
	var prev: float = float(_heat.get(faction_id, 0.0))
	var next: float = clampf(prev + amount, 0.0, MAX_HEAT)
	_heat[faction_id] = next
	heat_changed.emit(faction_id, next)
	_check_threshold(faction_id, prev, next)


func get_heat(faction_id: StringName) -> float:
	return float(_heat.get(faction_id, 0.0))


func get_all_heat() -> Dictionary:
	return _heat.duplicate(true)


func is_noticed(faction_id: StringName) -> bool:
	return get_heat(faction_id) >= THRESHOLD_NOTICED


func is_hostile(faction_id: StringName) -> bool:
	return get_heat(faction_id) >= THRESHOLD_HOSTILE


func reset() -> void:
	_heat.clear()
	_last_threshold.clear()


func to_save_dict() -> Dictionary:
	var heat_out: Dictionary = {}
	for k: Variant in _heat:
		heat_out[String(k)] = _heat[k]
	return {"heat": heat_out}


func from_save_dict(data: Dictionary) -> void:
	reset()
	var v: Variant = data.get("heat", {})
	if v is Dictionary:
		for k: Variant in v:
			_heat[StringName(str(k))] = float(v[k])


func _on_hour_changed(_hour: int) -> void:
	for faction_id: StringName in _heat.keys():
		var prev: float = float(_heat[faction_id])
		var next: float = maxf(prev - DECAY_PER_HOUR, 0.0)
		if next != prev:
			_heat[faction_id] = next
			heat_changed.emit(faction_id, next)
			_check_threshold(faction_id, prev, next)


func _check_threshold(faction_id: StringName, prev: float, next: float) -> void:
	for threshold: float in [THRESHOLD_NOTICED, THRESHOLD_HOSTILE]:
		if prev < threshold and next >= threshold:
			var last: float = float(_last_threshold.get(faction_id, -1.0))
			if last < threshold:
				_last_threshold[faction_id] = threshold
				heat_threshold_crossed.emit(faction_id, threshold)
		elif next < threshold:
			var last: float = float(_last_threshold.get(faction_id, -1.0))
			if last >= threshold:
				_last_threshold[faction_id] = threshold - 0.001
