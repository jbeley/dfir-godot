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
@export var prompt_override: String = ""
@export var faction_id: StringName = &""

signal dialogue_requested(npc: WorldNPC)


func _ready() -> void:
	add_to_group("hotspots")


func get_prompt() -> String:
	if prompt_override != "":
		return prompt_override
	return "[E] Talk to %s" % display_name


func interact() -> void:
	if npc_id != &"" and not JournalManager.has_met_npc(npc_id):
		JournalManager.record_npc_met(npc_id, display_name, Archetype.keys()[archetype], first_line)
	dialogue_requested.emit(self)
