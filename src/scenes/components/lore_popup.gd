extends CanvasLayer
class_name LorePopup

## Modal-ish popup used by SecretMarker reveals and other in-world finds.
## Pauses the tree while open. Closes on dismiss action or button press.

@onready var _title: Label = $Panel/Margin/V/Title
@onready var _body: Label = $Panel/Margin/V/Body
@onready var _button: Button = $Panel/Margin/V/CloseButton

var _was_paused: bool = false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button.pressed.connect(_close)


func show_text(title: String, body: String) -> void:
	_title.text = title
	_body.text = body
	_was_paused = get_tree().paused
	get_tree().paused = true
	_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		_close()


func _close() -> void:
	get_tree().paused = _was_paused
	queue_free()
