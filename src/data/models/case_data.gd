class_name CaseData
extends Resource
## Represents a single DFIR investigation case.

enum Status { PENDING, ACTIVE, COMPLETED, FAILED }
enum Severity { LOW, MEDIUM, HIGH, CRITICAL }

@export var case_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var severity: Severity = Severity.MEDIUM
@export var status: Status = Status.PENDING

## Client who reported the incident
@export var client: ClientData

## Deadline in total game hours from start of case
@export var deadline_hours: float = 48.0
@export var start_hour: float = 0.0

## Threat intelligence links
@export var cve_ids: PackedStringArray = []
@export var attack_technique_ids: PackedStringArray = []

## Evidence and ground truth
@export var evidence_items: Array[EvidenceData] = []
@export var correct_iocs: Array[IOCData] = []

## Player-discovered items (populated during investigation)
var discovered_iocs: Array[IOCData] = []
var mapped_techniques: PackedStringArray = []
var timeline_entries: Array[TimelineEvent] = []

## Reward
@export var reputation_reward: float = 5.0

## Is this case part of a story arc?
@export var story_arc_id: String = ""
@export var is_guided: bool = false  # Tutorial/guided cases have milestones


func get_hours_remaining() -> float:
	var current_hours := _get_time_hours()
	return deadline_hours - (current_hours - start_hour)


func is_overdue() -> bool:
	return get_hours_remaining() <= 0.0


func activate() -> void:
	status = Status.ACTIVE
	start_hour = _get_time_hours()


func _get_time_hours() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root.has_node("/root/TimeManager"):
		return tree.root.get_node("/root/TimeManager").call("get_total_hours")
	return 0.0
