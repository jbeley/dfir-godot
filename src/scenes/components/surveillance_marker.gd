extends Area2D
class_name SurveillanceMarker

## Like SecretMarker but adds heat to a faction the first time it's observed.
## Use for "you spotted a tail" moments — parked vans, unusual badges, etc.

@export var marker_id: StringName = &""
@export var display_name: String = "Something off"
@export var observation_text: String = ""
@export var faction_id: StringName = &""
@export var heat_amount: float = 8.0
@export var prompt: String = "[E] Take a closer look"

signal observed(marker: SurveillanceMarker)

var _observed_once: bool = false


func _ready() -> void:
	add_to_group("hotspots")


func get_prompt() -> String:
	if _observed_once:
		return ""
	return prompt


func interact() -> void:
	if _observed_once:
		return
	_observed_once = true
	var journal: Node = get_node_or_null("/root/JournalManager")
	if journal and marker_id != &"":
		journal.record_rumor_heard(marker_id, observation_text)
	var heat: Node = get_node_or_null("/root/HeatManager")
	if heat and faction_id != &"":
		heat.add_heat(faction_id, heat_amount)
	observed.emit(self)
