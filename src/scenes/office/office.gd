extends Node2D
## The WFH apartment hub scene. Top-down view of your home office.
## Interactive hotspots: desk, phone, evidence board, bed, coffee, cat.

@onready var player: CharacterBody2D = $Player
@onready var day_night: CanvasModulate = $DayNightModulate
@onready var interaction_label: Label = $UI/InteractionLabel
@onready var notification_label: Label = $UI/NotificationLabel

var current_hotspot: String = ""
var _hud: Node = null
var _pause_menu: Control = null
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

	# Tutorial hint
	TutorialManager.trigger("office_ready")

	# Add HUD
	var hud_scene := load("res://src/scenes/hud/game_hud.tscn") as PackedScene
	if hud_scene:
		_hud = hud_scene.instantiate()
		add_child(_hud)

	# Add touch controls for mobile
	var touch_scene := load("res://src/ui/components/touch_controls.tscn") as PackedScene
	if touch_scene:
		add_child(touch_scene.instantiate())

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


func _setup_hotspots() -> void:
	for hotspot: Node in get_tree().get_nodes_in_group("hotspots"):
		if hotspot is Area2D:
			hotspot.body_entered.connect(_on_hotspot_entered.bind(hotspot))
			hotspot.body_exited.connect(_on_hotspot_exited.bind(hotspot))


func _on_hotspot_entered(body: Node2D, hotspot: Area2D) -> void:
	if body == player:
		current_hotspot = hotspot.name
		player.set_nearby_interactable(hotspot)
		interaction_label.text = _get_hotspot_prompt(hotspot.name)
		interaction_label.visible = true


func _on_hotspot_exited(body: Node2D, hotspot: Area2D) -> void:
	if body == player and current_hotspot == hotspot.name:
		current_hotspot = ""
		player.clear_nearby_interactable(hotspot)
		interaction_label.visible = false


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


func _on_interruption(interruption: Dictionary) -> void:
	SfxBank.play("notification")
	var text: String = str(interruption.get("text", "Something happened..."))
	_show_notification(text, 4.0)


func _on_tutorial_hint(text: String) -> void:
	_show_notification(text, 6.0)


func _show_notification(text: String, duration: float = 3.0) -> void:
	notification_label.text = text
	notification_label.visible = true
	_notification_timer = duration


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
