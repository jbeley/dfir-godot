extends Node2D
## The WFH apartment hub scene. Top-down view of your home office.
## Interactive hotspots: desk, phone, evidence board, bed, coffee, cat.

@onready var player: CharacterBody2D = $Player
@onready var day_night: CanvasModulate = $DayNightModulate
@onready var interaction_label: Label = $UI/InteractionLabel

var current_hotspot: String = ""


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	player.interacted_with.connect(_on_player_interact)
	TimeManager.hour_changed.connect(_update_day_night)
	_update_day_night(TimeManager.current_hour)
	_setup_hotspots()


func _setup_hotspots() -> void:
	# Connect all hotspot areas
	for hotspot in get_tree().get_nodes_in_group("hotspots"):
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
		"Phone": return "[E] Check phone"
		"EvidenceBoard": return "[E] Evidence board"
		"Bed": return "[E] Sleep"
		"Coffee": return "[E] Make coffee"
		"Cat": return "[E] Pet the cat"
	return "[E] Interact"


func _on_player_interact(target: Node2D) -> void:
	match target.name:
		"Desk":
			GameManager.change_scene("res://src/scenes/workstation/workstation.tscn")
		"EvidenceBoard":
			GameManager.change_scene("res://src/scenes/evidence_board/evidence_board.tscn")
		"Bed":
			ReputationManager.sleep()
			TimeManager.current_hour = 8
			TimeManager.current_minute = 0
			TimeManager._advance_day()
		"Coffee":
			ReputationManager.drink_coffee()
		"Cat":
			ReputationManager.pet_cat()
		"Phone":
			pass  # TODO: Phone/dialogue scene


func _update_day_night(_hour: int) -> void:
	var darkness := TimeManager.get_darkness()
	var night_color := Color(0.4, 0.4, 0.6)  # Bluish tint at night
	var day_color := Color.WHITE
	day_night.color = day_color.lerp(night_color, darkness)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		GameManager.change_state(GameManager.GameState.PAUSED)
		# TODO: Open pause menu
