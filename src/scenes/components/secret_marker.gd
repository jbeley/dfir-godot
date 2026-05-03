extends Area2D
class_name SecretMarker

## Hidden discoverable. Records to the journal on first interact, then sits
## inert. Emits revealed signal so the scene can show a lore popup or whatever.

@export var secret_id: StringName = &""
@export var display_name: String = "Curious thing"
@export var lore_text: String = ""
@export var prompt: String = "[E] Investigate"

signal revealed(marker: SecretMarker)


func _ready() -> void:
	add_to_group("hotspots")
	if secret_id != &"":
		var journal: Node = get_node_or_null("/root/JournalManager")
		if journal:
			journal.register_secret(secret_id)


func get_prompt() -> String:
	if secret_id == &"":
		return prompt
	var journal: Node = get_node_or_null("/root/JournalManager")
	if journal and journal.has_found_secret(secret_id):
		return ""
	return prompt


func interact() -> void:
	if secret_id == &"":
		return
	var journal: Node = get_node_or_null("/root/JournalManager")
	if journal == null:
		return
	if journal.has_found_secret(secret_id):
		return
	journal.record_secret_found(secret_id, display_name, lore_text)
	revealed.emit(self)
