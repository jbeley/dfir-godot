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
@export var sprite_texture: Texture2D
@export var name_label_visible: bool = true

signal dialogue_requested(npc: WorldNPC)

var _line_index: int = 0


func _ready() -> void:
	add_to_group("hotspots")
	_setup_visuals()


func _setup_visuals() -> void:
	const NpcSpriteRegistry := preload(
		"res://src/systems/world/npc_sprite_registry.gd"
	)
	var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D
	# Inspector override wins; otherwise look up by npc_id.
	var tex: Texture2D = sprite_texture
	if tex == null and npc_id != &"":
		tex = NpcSpriteRegistry.get_sprite(npc_id)
	if sprite and tex != null:
		sprite.texture = tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var placeholder: ColorRect = get_node_or_null("Placeholder") as ColorRect
		if placeholder:
			placeholder.visible = false
	var name_label: Label = get_node_or_null("NameLabel") as Label
	if name_label:
		name_label.visible = name_label_visible
		name_label.text = display_name


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
	if journal and npc_id != &"":
		# Always overwrite — last_line should be the most recent thing they
		# said. JournalManager only fires npc_met on the first record.
		journal.record_npc_met(npc_id, display_name, Archetype.keys()[archetype], line)
		if faction_id != &"" and _line_index == 0:
			journal.record_faction_interaction(faction_id, 1)
	# Emit *before* advancing so the handler shows the line we just observed,
	# not the next one in the cycle.
	dialogue_requested.emit(self)
	_line_index += 1
