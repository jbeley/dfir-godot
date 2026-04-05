class_name AttackTechnique
extends Resource
## Represents a MITRE ATT&CK technique.

@export var technique_id: String = ""     # e.g. "T1059.001"
@export var name: String = ""             # e.g. "PowerShell"
@export var description: String = ""
@export var tactic: String = ""           # e.g. "execution"
@export var tactics: PackedStringArray = []  # Some techniques span multiple tactics
@export var is_subtechnique: bool = false
@export var parent_id: String = ""        # Parent technique ID if subtechnique
@export var detection_hint: String = ""   # Hint for players
@export var data_sources: PackedStringArray = []  # What evidence types reveal this

## All 14 ATT&CK Enterprise tactics
const TACTICS: Array[String] = [
	"reconnaissance",
	"resource-development",
	"initial-access",
	"execution",
	"persistence",
	"privilege-escalation",
	"defense-evasion",
	"credential-access",
	"discovery",
	"lateral-movement",
	"collection",
	"command-and-control",
	"exfiltration",
	"impact",
]


static func from_dict(data: Dictionary) -> AttackTechnique:
	var tech := AttackTechnique.new()
	tech.technique_id = data.get("technique_id", "")
	tech.name = data.get("name", "")
	tech.description = data.get("description", "")
	tech.tactic = data.get("tactic", "")
	tech.is_subtechnique = "." in tech.technique_id

	var tactics_data: Variant = data.get("tactics", [])
	if tactics_data is Array:
		var tactics_array: Array = tactics_data as Array
		for t: Variant in tactics_array:
			tech.tactics.append(str(t))

	if tech.is_subtechnique:
		tech.parent_id = tech.technique_id.split(".")[0]
	return tech
