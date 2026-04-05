extends Node
## Global game state manager. Handles scene transitions, save/load, and game state.

enum GameState { MENU, PLAYING, PAUSED }

var current_state: GameState = GameState.MENU

signal state_changed(new_state: GameState)
signal scene_transition_started
signal scene_transition_finished


func change_state(new_state: GameState) -> void:
	var old_state := current_state
	current_state = new_state
	if old_state != new_state:
		state_changed.emit(new_state)


func change_scene(scene_path: String) -> void:
	scene_transition_started.emit()
	# Use Godot's built-in scene changer - handles freeing old scene safely
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to: %s (error %d)" % [scene_path, err])
		return
	# Wait for the scene to be ready
	await get_tree().tree_changed
	scene_transition_finished.emit()


func save_game(slot: int = 0) -> void:
	var save_path := "user://saves/save_%d.json" % slot
	DirAccess.make_dir_recursive_absolute("user://saves")

	var save_data := {
		"version": 2,
		"timestamp": Time.get_datetime_string_from_system(),
		"reputation": ReputationManager.reputation,
		"career_tier": ReputationManager.career_tier,
		"total_completed": ReputationManager.total_cases_completed,
		"total_failed": ReputationManager.total_cases_failed,
		"time": {
			"day": TimeManager.current_day,
			"hour": TimeManager.current_hour,
			"minute": TimeManager.current_minute,
		},
		"stats": {
			"focus": ReputationManager.focus,
			"energy": ReputationManager.energy,
			"stress": ReputationManager.stress,
		},
		"campaign": {
			"act": CampaignManager.current_act,
			"completed_arcs": CampaignManager.completed_arcs,
			"total_cases": CampaignManager.total_cases_completed,
		},
	}

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()


func load_game(slot: int = 0) -> bool:
	var save_path := "user://saves/save_%d.json" % slot
	if not FileAccess.file_exists(save_path):
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	file.close()
	if result != OK:
		return false

	var data: Dictionary = json.data
	ReputationManager.reputation = float(data.get("reputation", 50.0))
	ReputationManager.career_tier = int(data.get("career_tier", 0))

	var time_data: Dictionary = data.get("time", {}) as Dictionary
	TimeManager.current_day = int(time_data.get("day", 1))
	TimeManager.current_hour = int(time_data.get("hour", 8))
	TimeManager.current_minute = int(time_data.get("minute", 0))

	var stats: Dictionary = data.get("stats", {}) as Dictionary
	ReputationManager.focus = float(stats.get("focus", 100.0))
	ReputationManager.energy = float(stats.get("energy", 100.0))
	ReputationManager.stress = float(stats.get("stress", 0.0))
	ReputationManager.total_cases_completed = int(data.get("total_completed", 0))
	ReputationManager.total_cases_failed = int(data.get("total_failed", 0))

	# Restore campaign state
	var campaign: Dictionary = data.get("campaign", {}) as Dictionary
	CampaignManager.current_act = int(campaign.get("act", 0))
	CampaignManager.total_cases_completed = int(campaign.get("total_cases", 0))
	var arcs: Variant = campaign.get("completed_arcs", {})
	if arcs is Dictionary:
		CampaignManager.completed_arcs = arcs as Dictionary

	return true


func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists("user://saves/save_%d.json" % slot)
