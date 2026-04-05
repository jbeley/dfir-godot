extends Node
## Manages the campaign story progression across multiple cases.
## Three interconnected arcs that converge in Act 3.

signal act_started(act: int, title: String)
signal arc_progressed(arc_id: String, case_index: int)
signal campaign_completed

enum Act { ACT_1, ACT_2, ACT_3, EPILOGUE }

var current_act: Act = Act.ACT_1
var completed_arcs: Dictionary = {}  # arc_id -> Array of completed case indices
var total_cases_completed: int = 0

# Story arc definitions
const ARCS := {
	"darklock": {
		"name": "DarkLock Ransomware Gang",
		"description": "A ransomware group escalating from small businesses to critical infrastructure.",
		"act": 0,  # Starts in Act 1
		"cases": [
			{
				"title": "Ransomware Incident - Acme Widget Corp",
				"description": "Small manufacturer hit by DarkLock ransomware. Your first real case.",
				"type": "ransomware",
				"severity": 3,
				"techniques": ["T1566.001", "T1059.001", "T1486", "T1070.001"],
				"deadline_hours": 48.0,
				"reveals": "DarkLock uses phishing with macro-enabled docs for initial access.",
			},
			{
				"title": "DarkLock Returns - Regional Hospital",
				"description": "DarkLock hits a hospital network. Patient data at risk. Stakes are higher.",
				"type": "ransomware",
				"severity": 3,
				"techniques": ["T1566.001", "T1059.001", "T1486", "T1053.005", "T1021.001"],
				"deadline_hours": 36.0,
				"reveals": "DarkLock has evolved - now using RDP lateral movement.",
			},
			{
				"title": "DarkLock Infrastructure Takedown",
				"description": "Law enforcement needs your analysis to support a takedown operation.",
				"type": "ransomware",
				"severity": 3,
				"techniques": ["T1566.001", "T1059.001", "T1486", "T1071.001", "T1041"],
				"deadline_hours": 24.0,
				"reveals": "DarkLock C2 infrastructure identified. FBI is moving.",
			},
		],
	},
	"phantom": {
		"name": "Phantom Bear APT",
		"description": "A nation-state APT conducting espionage against defense contractors.",
		"act": 1,  # Starts in Act 2
		"cases": [
			{
				"title": "Suspected APT - Meridian Defense Systems",
				"description": "Unusual beaconing detected from a defense contractor's network.",
				"type": "apt",
				"severity": 3,
				"techniques": ["T1190", "T1059.001", "T1053.005", "T1071.001"],
				"deadline_hours": 72.0,
				"reveals": "Phantom Bear uses compromised VPN appliances for initial access.",
			},
			{
				"title": "Phantom Bear - Supply Chain Compromise",
				"description": "The APT compromised a software vendor used by multiple defense contractors.",
				"type": "apt",
				"severity": 3,
				"techniques": ["T1195.002", "T1059.001", "T1071.001", "T1041", "T1005"],
				"deadline_hours": 48.0,
				"reveals": "Supply chain attack - trojanized update mechanism.",
			},
		],
	},
	"insider": {
		"name": "The Insider",
		"description": "A corporate insider systematically exfiltrating trade secrets.",
		"act": 0,  # Starts in Act 1
		"cases": [
			{
				"title": "Data Leak Investigation - TechVault Inc",
				"description": "Confidential product designs appeared on a competitor's marketing materials.",
				"type": "insider",
				"severity": 2,
				"techniques": ["T1074.001", "T1567.002", "T1048.003", "T1083"],
				"deadline_hours": 36.0,
				"reveals": "Employee used personal cloud storage to exfiltrate files.",
			},
			{
				"title": "The Insider - Following the Money",
				"description": "The suspected insider has connections to a foreign competitor.",
				"type": "insider",
				"severity": 3,
				"techniques": ["T1074.001", "T1567.002", "T1048.003", "T1078"],
				"deadline_hours": 48.0,
				"reveals": "Insider was recruited by a competitor through LinkedIn.",
			},
		],
	},
	"convergence": {
		"name": "Convergence",
		"description": "All three threat actors converge on the same target.",
		"act": 2,  # Act 3
		"cases": [
			{
				"title": "Operation Convergence - Sentinel Corp",
				"description": "DarkLock ransomware, Phantom Bear espionage, AND an insider threat - all hitting the same defense contractor simultaneously. This is the big one.",
				"type": "apt",
				"severity": 3,
				"techniques": ["T1566.001", "T1190", "T1059.001", "T1486", "T1071.001", "T1041", "T1078"],
				"deadline_hours": 72.0,
				"reveals": "The convergence was not coincidental. Someone orchestrated it.",
			},
		],
	},
}

const ACT_NAMES := ["Act 1: First Blood", "Act 2: Escalation", "Act 3: Convergence", "Epilogue: Endless"]


func _ready() -> void:
	CaseManager.case_completed.connect(_on_case_completed)


func get_current_act_name() -> String:
	return ACT_NAMES[current_act]


func get_available_arcs() -> Array[String]:
	var available: Array[String] = []
	for arc_id: String in ARCS:
		var arc: Dictionary = ARCS[arc_id]
		if int(arc.get("act", 0)) <= current_act:
			available.append(arc_id)
	return available


func get_next_case_for_arc(arc_id: String) -> Dictionary:
	if not ARCS.has(arc_id):
		return {}
	var arc: Dictionary = ARCS[arc_id]
	var cases: Array = arc.get("cases", [])
	var completed_count: int = completed_arcs.get(arc_id, []).size()
	if completed_count < cases.size():
		return cases[completed_count]
	return {}


func _on_case_completed(case_data: Resource, _score: float) -> void:
	total_cases_completed += 1

	# Check for arc progression
	if case_data.has_method("get") and case_data.get("story_arc_id") != null and str(case_data.get("story_arc_id")) != "":
		var arc_id: String = str(case_data.get("story_arc_id"))
		if not completed_arcs.has(arc_id):
			completed_arcs[arc_id] = []
		completed_arcs[arc_id].append(total_cases_completed)
		arc_progressed.emit(arc_id, completed_arcs[arc_id].size())

	# Check for act progression
	_check_act_progression()


func _check_act_progression() -> void:
	match current_act:
		Act.ACT_1:
			# Need to complete at least 1 case from darklock and 1 from insider
			var dl_done: int = completed_arcs.get("darklock", []).size()
			var ins_done: int = completed_arcs.get("insider", []).size()
			if dl_done >= 1 and ins_done >= 1:
				current_act = Act.ACT_2
				act_started.emit(2, ACT_NAMES[Act.ACT_2])
				SfxBank.play("promotion")
		Act.ACT_2:
			# Need to complete phantom bear arc
			var pb_done: int = completed_arcs.get("phantom", []).size()
			if pb_done >= 2:
				current_act = Act.ACT_3
				act_started.emit(3, ACT_NAMES[Act.ACT_3])
				SfxBank.play("promotion")
		Act.ACT_3:
			var conv_done: int = completed_arcs.get("convergence", []).size()
			if conv_done >= 1:
				current_act = Act.EPILOGUE
				campaign_completed.emit()
				SfxBank.play("case_complete")


func is_campaign_complete() -> bool:
	return current_act == Act.EPILOGUE
