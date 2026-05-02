extends Node2D
## The WFH apartment hub scene. Top-down view of your home office.
## Interactive hotspots: desk, phone, evidence board, bed, coffee, cat.

@onready var player: CharacterBody2D = $Player
@onready var day_night: CanvasModulate = $DayNightModulate
@onready var interaction_label: Label = $UI/InteractionLabel
@onready var interaction_bg: ColorRect = $UI/InteractionBG
@onready var notification_label: Label = $UI/NotificationLabel
@onready var notification_bg: ColorRect = $UI/NotificationBG
@onready var floor_rect: ColorRect = $Floor
@onready var wall_bg: ColorRect = $WallBG
@onready var wall_trim: ColorRect = $WallTrim
@onready var rug_sprite: Sprite2D = $Rug

var current_hotspot: String = ""
var _hud: Node = null
var _pause_menu: Control = null
var _highlight_node: Node2D = null
var _notification_timer: float = 0.0


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	SfxBank.play_music("chill")
	player.interacted_with.connect(_on_player_interact)
	TimeManager.hour_changed.connect(_update_day_night)
	InterruptionManager.interruption_triggered.connect(_on_interruption)
	TutorialManager.hint_shown.connect(_on_tutorial_hint)
	_update_day_night(TimeManager.current_hour)
	_setup_hotspots()
	_apply_apartment_visuals()
	_position_player_for_arrival()
	JournalManager.record_location_visited(&"apartment")

	# Tutorial hint
	TutorialManager.trigger("office_ready")

	# Add HUD
	var hud_scene := load("res://src/scenes/hud/game_hud.tscn") as PackedScene
	if hud_scene:
		_hud = hud_scene.instantiate()
		add_child(_hud)


	# Show case notification if there are active cases
	if CaseManager.get_active_case_count() > 0:
		_show_notification("Active case! Press E at desk to investigate.")
	else:
		_show_notification("Check your phone for new cases.")

	notification_label.visible = false


func _process(delta: float) -> void:
	if _notification_timer > 0:
		_notification_timer -= delta
		if _notification_timer <= 0:
			notification_label.visible = false
			if notification_bg:
				notification_bg.visible = false
	# Pulse the hotspot highlight
	if _highlight_node and is_instance_valid(_highlight_node):
		var pulse: float = 0.4 + 0.5 * (sin(Time.get_ticks_msec() / 200.0) * 0.5 + 0.5)
		_highlight_node.modulate = Color(1, 1, 0.5, pulse)


func _position_player_for_arrival() -> void:
	var spawn_id: StringName = WorldManager.consume_spawn_id()
	var marker_name := "DefaultSpawn"
	if spawn_id == &"from_street":
		marker_name = "FromStreetSpawn"
	var marker: Node2D = get_node_or_null(marker_name) as Node2D
	if marker != null:
		player.global_position = marker.global_position


func _setup_hotspots() -> void:
	# Use player's InteractArea (Area2D with radius 28) to detect hotspots.
	# This bypasses physics collision - the interact circle just needs to
	# touch the hotspot, not the player's body.
	var interact_area: Area2D = player.get_node_or_null("InteractArea")
	if interact_area == null:
		push_error("Player has no InteractArea")
		return
	interact_area.area_entered.connect(_on_interact_area_entered)
	interact_area.area_exited.connect(_on_interact_area_exited)


func _on_interact_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hotspots"):
		return
	current_hotspot = area.name
	player.set_nearby_interactable(area)
	interaction_label.text = _get_hotspot_prompt(area.name)
	interaction_label.visible = true
	if interaction_bg:
		interaction_bg.visible = true
	_show_hotspot_highlight(area)
	SfxBank.play("menu_move")


func _on_interact_area_exited(area: Area2D) -> void:
	if not area.is_in_group("hotspots"):
		return
	if current_hotspot == area.name:
		current_hotspot = ""
		player.clear_nearby_interactable(area)
		interaction_label.visible = false
		if interaction_bg:
			interaction_bg.visible = false
		_hide_hotspot_highlight()


func _show_hotspot_highlight(area: Area2D) -> void:
	_hide_hotspot_highlight()
	_highlight_node = Node2D.new()
	_highlight_node.position = area.global_position
	# Draw a circle via Line2D
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(1, 1, 0.3, 0.8)
	var pts := PackedVector2Array()
	var radius := 22.0
	for i in range(33):
		var angle: float = i * TAU / 32.0
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	line.points = pts
	_highlight_node.add_child(line)
	add_child(_highlight_node)


func _hide_hotspot_highlight() -> void:
	if _highlight_node and is_instance_valid(_highlight_node):
		_highlight_node.queue_free()
	_highlight_node = null


func _get_hotspot_prompt(hotspot_name: String) -> String:
	match hotspot_name:
		"Desk": return "[E] Sit at workstation"
		"Phone":
			if CaseManager.get_active_case_count() > 0:
				return "[E] Call client"
			return "[E] Check email"
		"EvidenceBoard": return "[E] Evidence board"
		"Bed": return "[E] Sleep"
		"Coffee": return "[E] Make coffee"
		"Cat": return "[E] Pet the cat"
		"FrontDoor": return "[E] Step outside"
	return "[E] Interact"


func _on_player_interact(target: Node2D) -> void:
	SfxBank.play("interact")
	match target.name:
		"Desk":
			GameManager.change_scene("res://src/scenes/workstation/workstation.tscn")
		"EvidenceBoard":
			GameManager.change_scene("res://src/scenes/evidence_board/evidence_board.tscn")
		"Bed":
			SfxBank.play("sleep")
			ReputationManager.sleep()
			TimeManager.current_hour = 8
			TimeManager.current_minute = 0
			TimeManager._advance_day()
			_show_notification("Slept well. Energy restored!")
		"Coffee":
			SfxBank.play("coffee")
			ReputationManager.drink_coffee()
			_show_notification("Coffee! Energy +20")
		"Cat":
			SfxBank.play("cat_purr")
			ReputationManager.pet_cat()
			_show_notification("Purrrr... Stress -10")
			# Tell cat NPC to play petted animation
			var cat_node := get_node_or_null("CatNPC")
			if cat_node and cat_node.has_method("pet"):
				cat_node.pet()
		"Phone":
			if CaseManager.get_active_case_count() > 0:
				GameManager.change_scene("res://src/scenes/dialogue/dialogue_scene.tscn")
			else:
				GameManager.change_scene("res://src/scenes/email/email_client.tscn")
		"FrontDoor":
			WorldManager.travel_to(&"street_downtown", &"default")


func _on_interruption(interruption: Dictionary) -> void:
	SfxBank.play("notification")
	var text: String = str(interruption.get("text", "Something happened..."))
	_show_notification(text, 4.0)


func _on_tutorial_hint(text: String) -> void:
	_show_notification(text, 6.0)


func _show_notification(text: String, duration: float = 3.0) -> void:
	notification_label.text = text
	notification_label.visible = true
	if notification_bg:
		notification_bg.visible = true
	_notification_timer = duration


func _apply_apartment_visuals() -> void:
	var config: Dictionary = ApartmentManager.get_config()

	# Apply colors
	if floor_rect:
		floor_rect.color = config.get("floor_color", Color(0.22, 0.18, 0.15))
	if wall_bg:
		wall_bg.color = config.get("wall_color", Color(0.30, 0.28, 0.32))
	if wall_trim:
		wall_trim.color = config.get("trim_color", Color(0.45, 0.40, 0.35))
	if rug_sprite:
		rug_sprite.scale = config.get("rug_scale", Vector2(2.5, 2.2))

	# Add extra furniture for upgraded apartments
	var extras: Array = config.get("extra_furniture", [])
	var furniture_node := get_node_or_null("Furniture")
	if furniture_node == null:
		return

	for item: Variant in extras:
		var item_name: String = str(item)
		if furniture_node.has_node(item_name.capitalize()):
			continue  # Already exists
		_spawn_extra_furniture(furniture_node, item_name)


func _spawn_extra_furniture(parent: Node, item_name: String) -> void:
	var rect := ColorRect.new()
	rect.name = item_name.capitalize()

	match item_name:
		"plant":
			rect.position = Vector2(420, 200)
			rect.size = Vector2(16, 20)
			rect.color = Color(0.2, 0.5, 0.2)
		"lamp":
			rect.position = Vector2(130, 140)
			rect.size = Vector2(8, 24)
			rect.color = Color(0.7, 0.65, 0.4)
		"second_monitor":
			# Add next to existing desk
			rect.position = Vector2(320, 60)
			rect.size = Vector2(20, 16)
			rect.color = Color(0.1, 0.15, 0.2)
			var screen := ColorRect.new()
			screen.position = Vector2(2, 1)
			screen.size = Vector2(16, 12)
			screen.color = Color(0.15, 0.35, 0.15)
			rect.add_child(screen)
		"whiteboard":
			rect.position = Vector2(340, 8)
			rect.size = Vector2(50, 28)
			rect.color = Color(0.9, 0.9, 0.88)
		"server_rack":
			rect.position = Vector2(450, 140)
			rect.size = Vector2(20, 40)
			rect.color = Color(0.15, 0.15, 0.18)
			# Blinking lights
			var led := ColorRect.new()
			led.position = Vector2(4, 4)
			led.size = Vector2(3, 2)
			led.color = Color(0.0, 0.8, 0.0)
			rect.add_child(led)
		"awards":
			rect.position = Vector2(160, 8)
			rect.size = Vector2(30, 14)
			rect.color = Color(0.5, 0.4, 0.2)

	parent.add_child(rect)


func _update_day_night(_hour: int) -> void:
	var darkness := TimeManager.get_darkness()
	var night_color := Color(0.4, 0.4, 0.6)
	var day_color := Color.WHITE
	day_night.color = day_color.lerp(night_color, darkness)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if _pause_menu and _pause_menu.visible:
			_close_pause_menu()
		else:
			_open_pause_menu()


func _open_pause_menu() -> void:
	GameManager.change_state(GameManager.GameState.PAUSED)
	get_tree().paused = true

	if _pause_menu:
		_pause_menu.visible = true
		return

	_pause_menu = Control.new()
	_pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	_pause_menu.add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -60
	vbox.offset_top = -50
	vbox.offset_right = 60
	vbox.offset_bottom = 50
	vbox.add_theme_constant_override("separation", 6)
	_pause_menu.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_close_pause_menu)
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(resume_btn)

	var save_btn := Button.new()
	save_btn.text = "Save Game"
	save_btn.pressed.connect(func() -> void:
		GameManager.save_game()
		_show_notification("Game saved!")
		_close_pause_menu()
	)
	save_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(save_btn)

	var quit_btn := Button.new()
	quit_btn.text = "Quit to Menu"
	quit_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		GameManager.change_scene("res://src/scenes/main_menu/main_menu.tscn")
	)
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(quit_btn)

	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 100
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(_pause_menu)
	add_child(ui_layer)

	resume_btn.grab_focus()


func _close_pause_menu() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	get_tree().paused = false
	if _pause_menu:
		_pause_menu.visible = false
