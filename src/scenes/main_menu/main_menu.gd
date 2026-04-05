extends Control
## Main menu scene. Title screen with New Game, Continue, Settings, Quit.

@onready var new_game_btn: Button = %NewGameBtn
@onready var continue_btn: Button = %ContinueBtn
@onready var settings_btn: Button = %SettingsBtn
@onready var quit_btn: Button = %QuitBtn
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MENU)

	# Check for existing save
	continue_btn.disabled = not GameManager.has_save()

	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)

	version_label.text = "v0.2.0 - Phase 2"

	# Auto-focus first button for gamepad
	new_game_btn.call_deferred("grab_focus")


func _on_new_game() -> void:
	# Load the tutorial case
	var tutorial_case := SampleCaseLoader.create_tutorial_case()
	tutorial_case.activate()
	CaseManager.add_case(tutorial_case)

	GameManager.change_scene("res://src/scenes/office/office.tscn")
	GameManager.change_state(GameManager.GameState.PLAYING)


func _on_continue() -> void:
	if GameManager.load_game():
		GameManager.change_scene("res://src/scenes/office/office.tscn")
		GameManager.change_state(GameManager.GameState.PLAYING)


func _on_settings() -> void:
	GameManager.change_scene("res://src/scenes/settings/settings_menu.tscn")


func _on_quit() -> void:
	get_tree().quit()
