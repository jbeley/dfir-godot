extends Control
## Main menu scene. Title screen with New Game, Continue, Settings, Quit.

@onready var new_game_btn: Button = %NewGameBtn
@onready var continue_btn: Button = %ContinueBtn
@onready var settings_btn: Button = %SettingsBtn
@onready var quit_btn: Button = %QuitBtn
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	SfxBank.play_music("menu")

	# Hide Continue when no save exists, instead of dimming it. New players
	# don't have to wonder what's behind the greyed-out option.
	var has_save: bool = GameManager.has_save()
	continue_btn.visible = has_save
	continue_btn.disabled = not has_save

	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)

	version_label.text = "v0.2.1"

	# Auto-focus first button for gamepad
	new_game_btn.call_deferred("grab_focus")


func _on_new_game() -> void:
	# Disable buttons to prevent double-click
	new_game_btn.disabled = true

	# Load the tutorial case
	var tutorial_case := SampleCaseLoader.create_tutorial_case()
	tutorial_case.activate()
	CaseManager.add_case(tutorial_case)

	GameManager.change_state(GameManager.GameState.PLAYING)
	get_tree().change_scene_to_file("res://src/scenes/office/office.tscn")


func _on_continue() -> void:
	if GameManager.load_game():
		GameManager.change_state(GameManager.GameState.PLAYING)
		get_tree().change_scene_to_file("res://src/scenes/office/office.tscn")


func _on_settings() -> void:
	GameManager.change_scene("res://src/scenes/settings/settings_menu.tscn")


func _on_quit() -> void:
	get_tree().quit()
