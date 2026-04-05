class_name TypewriterLabel
extends RichTextLabel
## Displays text character-by-character with a typewriter effect.

@export var characters_per_second: float = 30.0
@export var auto_start: bool = false

var _full_text: String = ""
var _current_index: int = 0
var _timer: float = 0.0
var _is_typing: bool = false

signal typing_finished


func _ready() -> void:
	bbcode_enabled = true
	if auto_start and text != "":
		start_typing(text)


func _process(delta: float) -> void:
	if not _is_typing:
		return

	_timer += delta
	var chars_to_show := int(_timer * characters_per_second)
	if chars_to_show > _current_index:
		_current_index = mini(chars_to_show, _full_text.length())
		visible_characters = _current_index

		if _current_index >= _full_text.length():
			_is_typing = false
			typing_finished.emit()


func start_typing(new_text: String) -> void:
	_full_text = new_text
	text = new_text
	_current_index = 0
	_timer = 0.0
	visible_characters = 0
	_is_typing = true


func skip_to_end() -> void:
	_is_typing = false
	visible_characters = -1  # Show all
	typing_finished.emit()


func is_typing() -> bool:
	return _is_typing
