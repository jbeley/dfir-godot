extends Area2D
class_name WorldNPC

## Static dialogue NPC for world scenes. Place in any world scene; on interact()
## it records first-meet in the journal and emits dialogue_requested with a
## dialogue path the scene can route to the dialogue system. Keep this dumb —
## the scene wires up how dialogue actually plays.

enum Archetype { RECURRING, FLAVOR, SECRET, FACTION }

@export var npc_id: StringName = &""
@export var display_name: String = "NPC"
@export var archetype: Archetype = Archetype.FLAVOR
@export var dialogue_path: String = ""
@export var first_line: String = "..."
@export var lines: PackedStringArray = PackedStringArray()
@export var prompt_override: String = ""
@export var faction_id: StringName = &""

signal dialogue_requested(npc: WorldNPC)

var _line_index: int = 0


func _ready() -> void:
	add_to_group("hotspots")


func get_prompt() -> String:
	if prompt_override != "":
		return prompt_override
	return "[E] Talk to %s" % display_name


func get_current_line() -> String:
	if lines.size() == 0:
		return first_line
	return lines[_line_index % lines.size()]


func interact() -> void:
	var line: String = get_current_line()
	# Look up the journal autoload at runtime so this script also loads
	# cleanly in test harnesses where autoloads aren't registered.
	var journal: Node = get_node_or_null("/root/JournalManager")
	if journal:
		if npc_id != &"" and not journal.has_met_npc(npc_id):
			journal.record_npc_met(npc_id, display_name, Archetype.keys()[archetype], line)
		if faction_id != &"" and _line_index == 0:
			journal.record_faction_interaction(faction_id, 1)
	_line_index += 1
	dialogue_requested.emit(self)
