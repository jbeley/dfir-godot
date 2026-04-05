class_name FocusButton
extends Button
## A button that plays nicely with gamepad navigation.
## Auto-grabs focus when marked as default. Plays SFX on focus.

@export var is_default_focus: bool = false


func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	if is_default_focus:
		call_deferred("grab_focus")


func _on_focus_entered() -> void:
	# Visual pulse when focused via gamepad
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
