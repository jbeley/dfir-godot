extends Node
## Manages the lifecycle of all investigation cases.

var active_cases: Array = []  # Array of CaseData resources
var completed_cases: Array = []
var failed_cases: Array = []

signal case_received(case_data: Resource)
signal case_activated(case_data: Resource)
signal case_completed(case_data: Resource, score: float)
signal case_failed(case_data: Resource, reason: String)
signal case_deadline_warning(case_data: Resource, hours_remaining: float)


func _ready() -> void:
	TimeManager.hour_changed.connect(_check_deadlines)


func add_case(case_data: Resource) -> void:
	active_cases.append(case_data)
	case_received.emit(case_data)


func complete_case(case_data: Resource, score: float) -> void:
	active_cases.erase(case_data)
	completed_cases.append(case_data)
	case_completed.emit(case_data, score)


func fail_case(case_data: Resource, reason: String) -> void:
	active_cases.erase(case_data)
	failed_cases.append(case_data)
	case_failed.emit(case_data, reason)


func get_active_case_count() -> int:
	return active_cases.size()


func _check_deadlines(_hour: int) -> void:
	var current_hours := TimeManager.get_total_hours()
	for case_data in active_cases:
		if not case_data.has_method("get") or not case_data.get("deadline_hours"):
			continue
		var remaining: float = case_data.deadline_hours - current_hours
		if remaining <= 0:
			fail_case(case_data, "Deadline expired")
		elif remaining <= 4:
			case_deadline_warning.emit(case_data, remaining)
