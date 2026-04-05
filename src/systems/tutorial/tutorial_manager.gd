extends Node
## Guided tutorial system. Shows hints at key moments during the first case.
## Tracks which hints have been shown to avoid repetition.

signal hint_shown(text: String)

var hints_shown: Dictionary = {}
var tutorial_active: bool = true

const HINTS := {
	"first_boot": {
		"text": "Welcome, Intern! Check your phone [E] to receive your first case assignment.",
		"trigger": "office_ready",
	},
	"check_email": {
		"text": "Walk to the phone on the desk and press [E] to check your email.",
		"trigger": "near_phone",
	},
	"case_accepted": {
		"text": "Case accepted! Walk to your desk and press [E] to open the workstation terminal.",
		"trigger": "case_received",
	},
	"terminal_basics": {
		"text": "Type 'help' to see available commands. Try 'ls' to list evidence files.",
		"trigger": "terminal_opened",
	},
	"first_grep": {
		"text": "Try: cat /evidence/logs/Security.evtx | grep Failed\nThis searches for failed login attempts.",
		"trigger": "first_ls",
	},
	"track_ioc": {
		"text": "Found a suspicious IP? Track it with: ioc add ip 192.168.1.50",
		"trigger": "first_grep",
	},
	"add_timeline": {
		"text": "Build your timeline: timeline add 2024-01-14T23:00 Brute force from 192.168.1.50",
		"trigger": "first_ioc",
	},
	"map_technique": {
		"text": "Map ATT&CK techniques: technique add T1110.001 (Brute Force)\nUse 'technique search' for a reference.",
		"trigger": "first_timeline",
	},
	"submit_case": {
		"text": "Ready to submit? Type 'submit' to get your investigation scored!",
		"trigger": "has_all_components",
	},
	"call_client": {
		"text": "You can call your client from the phone to gather more information.",
		"trigger": "case_in_progress",
	},
	"evidence_board": {
		"text": "Use the evidence board on the wall to visually organize your findings.",
		"trigger": "near_board",
	},
}

var _pending_hints: Array[String] = []


func _ready() -> void:
	CaseManager.case_received.connect(_on_case_received)
	ReputationManager.promoted.connect(_on_promoted)


func show_hint(hint_id: String) -> void:
	if not tutorial_active:
		return
	if hints_shown.has(hint_id):
		return

	if not HINTS.has(hint_id):
		return

	hints_shown[hint_id] = true
	var hint_data: Dictionary = HINTS[hint_id]
	var text: String = str(hint_data.get("text", ""))
	hint_shown.emit(text)


func trigger(event: String) -> void:
	if not tutorial_active:
		return
	for hint_id: String in HINTS:
		if hints_shown.has(hint_id):
			continue
		var hint_data: Dictionary = HINTS[hint_id]
		if str(hint_data.get("trigger", "")) == event:
			show_hint(hint_id)
			return


func _on_case_received(_case_data: Resource) -> void:
	trigger("case_received")


func _on_promoted(_tier: int, _name: String) -> void:
	if _tier >= 2:  # Analyst - disable tutorials
		tutorial_active = false


func disable() -> void:
	tutorial_active = false
