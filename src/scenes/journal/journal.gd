extends CanvasLayer
class_name JournalOverlay

## Read-only view over JournalManager state. Pauses while open. Opens via
## the "open_journal" input action. Tabs: locations, NPCs, secrets, rumors,
## factions.

@onready var _tabs: TabContainer = $Panel/Margin/V/Tabs
@onready var _locations_list: ItemList = $Panel/Margin/V/Tabs/Locations/ScrollContainer/Locations
@onready var _npcs_list: ItemList = $Panel/Margin/V/Tabs/NPCs/ScrollContainer/NPCs
@onready var _secrets_label: Label = $Panel/Margin/V/Tabs/Secrets/V/Counter
@onready var _secrets_list: ItemList = $Panel/Margin/V/Tabs/Secrets/V/ScrollContainer/Secrets
@onready var _rumors_list: ItemList = $Panel/Margin/V/Tabs/Rumors/ScrollContainer/Rumors
@onready var _factions_list: ItemList = $Panel/Margin/V/Tabs/Factions/ScrollContainer/Factions
@onready var _close_button: Button = $Panel/Margin/V/Footer/CloseButton

var _was_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_close_button.pressed.connect(close)
	_was_paused = get_tree().paused
	get_tree().paused = true
	_populate()
	_close_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_journal"):
		close()


func close() -> void:
	get_tree().paused = _was_paused
	queue_free()


func _populate() -> void:
	_populate_locations()
	_populate_npcs()
	_populate_secrets()
	_populate_rumors()
	_populate_factions()


func _populate_locations() -> void:
	_locations_list.clear()
	var visited: Dictionary = JournalManager.get_locations_visited()
	if visited.is_empty():
		_locations_list.add_item("(nowhere yet)")
		return
	for id: Variant in visited:
		var loc: Resource = WorldManager.get_location(id)
		var name: String = String(id) if loc == null else loc.display_name
		var visits: int = int(visited[id])
		_locations_list.add_item("%s  -  visits: %d" % [name, visits])


func _populate_npcs() -> void:
	_npcs_list.clear()
	var npcs: Dictionary = JournalManager.get_npcs_met()
	if npcs.is_empty():
		_npcs_list.add_item("(no one yet)")
		return
	for id: Variant in npcs:
		var entry: Dictionary = npcs[id]
		_npcs_list.add_item(
			"%s [%s]" % [entry.get("display_name", id), entry.get("archetype", "?")]
		)


func _populate_secrets() -> void:
	_secrets_list.clear()
	var found: int = JournalManager.get_secrets_found_count()
	var known: int = JournalManager.get_secrets_known_count()
	_secrets_label.text = "Secrets found: %d / %d" % [found, known]
	if found == 0:
		_secrets_list.add_item("(nothing found yet)")
		return
	for id: Variant in JournalManager.get_secrets_found():
		var entry: Dictionary = JournalManager.get_secrets_found()[id]
		_secrets_list.add_item(entry.get("display_name", String(id)))


func _populate_rumors() -> void:
	_rumors_list.clear()
	var rumors: Dictionary = JournalManager.get_rumors_heard()
	if rumors.is_empty():
		_rumors_list.add_item("(no rumors yet)")
		return
	for id: Variant in rumors:
		_rumors_list.add_item(str(rumors[id]))


func _populate_factions() -> void:
	_factions_list.clear()
	var standings: Dictionary = JournalManager.get_all_faction_standings()
	if standings.is_empty():
		_factions_list.add_item("(no faction contact yet)")
		return
	for id: Variant in standings:
		_factions_list.add_item("%s: %d" % [str(id), int(standings[id])])
