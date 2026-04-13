extends Control
## Settings menu - audio, display, gameplay options.

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var game_speed_slider: HSlider = %GameSpeedSlider
@onready var game_speed_label: Label = %GameSpeedLabel
@onready var back_btn: Button = %BackBtn

const SETTINGS_PATH := "user://settings.json"


func _ready() -> void:
	_load_settings()
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	game_speed_slider.value_changed.connect(_on_game_speed_changed)
	back_btn.pressed.connect(_on_back)
	back_btn.grab_focus()


func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value / 100.0)
	_save_settings()


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)
	_save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func _on_game_speed_changed(value: float) -> void:
	TimeManager.game_minutes_per_second = value
	game_speed_label.text = "Game Speed: %.0fx" % value
	_save_settings()


func _on_back() -> void:
	GameManager.change_scene("res://src/scenes/main_menu/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


func _save_settings() -> void:
	var data := {
		"music_volume": music_slider.value,
		"sfx_volume": sfx_slider.value,
		"fullscreen": fullscreen_check.button_pressed,
		"game_speed": game_speed_slider.value,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		# Defaults
		music_slider.value = 80
		sfx_slider.value = 80
		game_speed_slider.value = 5
		game_speed_label.text = "Game Speed: 5x"
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data: Dictionary = json.data

	music_slider.value = float(data.get("music_volume", 80))
	sfx_slider.value = float(data.get("sfx_volume", 80))
	fullscreen_check.button_pressed = data.get("fullscreen", false)
	game_speed_slider.value = float(data.get("game_speed", 5))
	game_speed_label.text = "Game Speed: %.0fx" % game_speed_slider.value

	AudioManager.set_music_volume(music_slider.value / 100.0)
	AudioManager.set_sfx_volume(sfx_slider.value / 100.0)
	TimeManager.game_minutes_per_second = game_speed_slider.value
