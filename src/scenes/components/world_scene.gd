extends Node2D
class_name WorldScene

## Base for any walkable world scene (street, site, hangout). Handles:
##   - spawning the player at the SpawnPoint matching WorldManager's hand-off
##   - wiring InteractArea against any Area2D in the "hotspots" group
##   - showing a single prompt label
##   - dispatching interact to door/NPC/secret components
##
## Concrete scenes inherit and add their own overlays / NPC dialogue routing.

const HUD_SCENE: PackedScene = preload("res://src/scenes/hud/game_hud.tscn")
const PLAYER_SCENE: PackedScene = preload("res://src/scenes/office/player.tscn")
const POPUP_SCENE: PackedScene = preload("res://src/scenes/components/lore_popup.tscn")

@export var location_id: StringName = &""
@export var attach_hud: bool = true

var player: CharacterBody2D
var _prompt_label: Label
var _prompt_bg: ColorRect
var _current_hotspot: Area2D


func _ready() -> void:
	_ensure_player()
	_position_player_at_spawn()
	_build_prompt_ui()
	_wire_interactions()
	_wire_default_npc_and_secret_handlers()
	if attach_hud and not _has_hud():
		add_child(HUD_SCENE.instantiate())
	if location_id != &"":
		JournalManager.record_location_visited(location_id)
	GameManager.change_state(GameManager.GameState.PLAYING)


func _wire_default_npc_and_secret_handlers() -> void:
	for child in get_children():
		if child is WorldNPC and not child.dialogue_requested.is_connected(_on_npc_dialogue_default):
			(child as WorldNPC).dialogue_requested.connect(_on_npc_dialogue_default)
		if child is SecretMarker and not child.revealed.is_connected(_on_secret_revealed_default):
			(child as SecretMarker).revealed.connect(_on_secret_revealed_default)
		if (
			child is SurveillanceMarker
			and not child.observed.is_connected(_on_surveillance_observed_default)
		):
			(child as SurveillanceMarker).observed.connect(_on_surveillance_observed_default)


func _on_npc_dialogue_default(npc: WorldNPC) -> void:
	show_lore_popup(npc.display_name, npc.get_current_line())


func _on_secret_revealed_default(marker: SecretMarker) -> void:
	show_lore_popup(marker.display_name, marker.lore_text)


func _on_surveillance_observed_default(marker: SurveillanceMarker) -> void:
	show_lore_popup(marker.display_name, marker.observation_text)


func _ensure_player() -> void:
	player = get_node_or_null("Player") as CharacterBody2D
	if player != null:
		return
	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	add_child(player)


func _position_player_at_spawn() -> void:
	var want: StringName = WorldManager.consume_spawn_id()
	var fallback: SpawnPoint = null
	for child in get_children():
		var sp: SpawnPoint = child as SpawnPoint
		if sp == null:
			continue
		if fallback == null:
			fallback = sp
		if sp.id == want:
			player.global_position = sp.global_position
			return
	if fallback != null:
		player.global_position = fallback.global_position


func _build_prompt_ui() -> void:
	var layer: CanvasLayer = get_node_or_null("PromptLayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "PromptLayer"
		layer.layer = 5
		add_child(layer)
	_prompt_bg = ColorRect.new()
	_prompt_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_prompt_bg.offset_left = -90
	_prompt_bg.offset_right = 90
	_prompt_bg.offset_top = 200
	_prompt_bg.offset_bottom = 218
	_prompt_bg.color = Color(0.05, 0.1, 0.25, 0.85)
	_prompt_bg.visible = false
	layer.add_child(_prompt_bg)
	_prompt_label = Label.new()
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_prompt_label.offset_left = -88
	_prompt_label.offset_right = 88
	_prompt_label.offset_top = 201
	_prompt_label.offset_bottom = 217
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	layer.add_child(_prompt_label)


func _wire_interactions() -> void:
	var interact_area: Area2D = player.get_node_or_null("InteractArea") as Area2D
	if interact_area == null:
		push_error("WorldScene: player missing InteractArea")
		return
	interact_area.area_entered.connect(_on_interact_area_entered)
	interact_area.area_exited.connect(_on_interact_area_exited)
	if player.has_signal("interacted_with"):
		player.interacted_with.connect(_on_player_interact)


func _on_interact_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hotspots"):
		return
	var prompt_text: String = _hotspot_prompt(area)
	if prompt_text == "":
		return
	_current_hotspot = area
	player.set_nearby_interactable(area)
	_prompt_label.text = prompt_text
	_prompt_label.visible = true
	_prompt_bg.visible = true


func _on_interact_area_exited(area: Area2D) -> void:
	if area != _current_hotspot:
		return
	_current_hotspot = null
	player.clear_nearby_interactable(area)
	_prompt_label.visible = false
	_prompt_bg.visible = false


func _on_player_interact(target: Node) -> void:
	if target == null:
		return
	if target.has_method("interact"):
		target.interact()
		_refresh_prompt(target)
	on_hotspot_interact(target)


func on_hotspot_interact(_target: Node) -> void:
	## Override in concrete scenes to handle scene-specific hotspots
	## (e.g., NPC dialogue routing, custom site logic).
	pass


func show_lore_popup(title: String, body: String) -> void:
	var popup: Node = POPUP_SCENE.instantiate()
	add_child(popup)
	if popup.has_method("show_text"):
		popup.show_text(title, body)


func _hotspot_prompt(area: Area2D) -> String:
	if area.has_method("get_prompt"):
		return area.get_prompt()
	return "[E] Interact"


func _refresh_prompt(target: Node) -> void:
	if _current_hotspot != target:
		return
	var prompt_text: String = _hotspot_prompt(target as Area2D)
	if prompt_text == "":
		_prompt_label.visible = false
		_prompt_bg.visible = false
	else:
		_prompt_label.text = prompt_text


func _has_hud() -> bool:
	for child in get_children():
		if child is CanvasLayer and child.name == "GameHUD":
			return true
	return false
