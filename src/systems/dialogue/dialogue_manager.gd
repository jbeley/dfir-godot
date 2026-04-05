class_name DialogueManager
extends RefCounted
## Manages NPC conversations as a state machine.
## Dialogue trees are JSON: array of nodes with choices that affect trust.

## A single dialogue node
class DialogueNode:
	var id: String = ""
	var speaker: String = ""
	var text: String = ""
	var choices: Array[DialogueChoice] = []
	var next_id: String = ""  # Auto-advance if no choices
	var trust_change: float = 0.0
	var reveals_evidence: String = ""  # Evidence ID unlocked by this node
	var condition: String = ""  # Condition to show this node (e.g., "trust>3")

class DialogueChoice:
	var text: String = ""
	var next_id: String = ""
	var trust_change: float = 0.0
	var tone: String = "neutral"  # neutral, empathetic, aggressive, technical

var _nodes: Dictionary = {}  # id -> DialogueNode
var _current_node_id: String = ""
var _conversation_log: Array[String] = []

signal dialogue_started(speaker: String)
signal node_displayed(node: DialogueNode)
signal choice_selected(choice: DialogueChoice)
signal dialogue_ended
signal evidence_revealed(evidence_id: String)
signal trust_changed(amount: float)


func load_dialogue(data: Array) -> void:
	_nodes.clear()
	for entry: Variant in data:
		var d: Dictionary = entry as Dictionary
		var node := DialogueNode.new()
		node.id = str(d.get("id", ""))
		node.speaker = str(d.get("speaker", ""))
		node.text = str(d.get("text", ""))
		node.next_id = str(d.get("next", ""))
		node.trust_change = float(d.get("trust_change", 0.0))
		node.reveals_evidence = str(d.get("reveals_evidence", ""))
		node.condition = str(d.get("condition", ""))

		var choices_data: Variant = d.get("choices", [])
		if choices_data is Array:
			for c: Variant in choices_data as Array:
				var cd: Dictionary = c as Dictionary
				var choice := DialogueChoice.new()
				choice.text = str(cd.get("text", ""))
				choice.next_id = str(cd.get("next", ""))
				choice.trust_change = float(cd.get("trust_change", 0.0))
				choice.tone = str(cd.get("tone", "neutral"))
				node.choices.append(choice)

		_nodes[node.id] = node


func start(start_node_id: String = "start") -> void:
	if not _nodes.has(start_node_id):
		push_warning("Dialogue node '%s' not found" % start_node_id)
		return
	_current_node_id = start_node_id
	var node: DialogueNode = _nodes[start_node_id]
	dialogue_started.emit(node.speaker)
	_display_node(node)


func select_choice(index: int) -> void:
	var node: DialogueNode = _nodes.get(_current_node_id)
	if node == null or index >= node.choices.size():
		return

	var choice: DialogueChoice = node.choices[index]
	choice_selected.emit(choice)

	if choice.trust_change != 0.0:
		trust_changed.emit(choice.trust_change)

	if choice.next_id == "" or choice.next_id == "end":
		dialogue_ended.emit()
		return

	_advance_to(choice.next_id)


func _advance_to(node_id: String) -> void:
	if not _nodes.has(node_id):
		dialogue_ended.emit()
		return
	_current_node_id = node_id
	_display_node(_nodes[node_id])


func _display_node(node: DialogueNode) -> void:
	_conversation_log.append("%s: %s" % [node.speaker, node.text])
	node_displayed.emit(node)

	if node.trust_change != 0.0:
		trust_changed.emit(node.trust_change)

	if node.reveals_evidence != "":
		evidence_revealed.emit(node.reveals_evidence)

	# Auto-advance if no choices and has next
	if node.choices.is_empty() and node.next_id != "":
		if node.next_id == "end":
			dialogue_ended.emit()
		else:
			_advance_to(node.next_id)


func get_current_node() -> DialogueNode:
	return _nodes.get(_current_node_id)


func get_conversation_log() -> Array[String]:
	return _conversation_log


func is_active() -> bool:
	return _current_node_id != "" and _nodes.has(_current_node_id)
