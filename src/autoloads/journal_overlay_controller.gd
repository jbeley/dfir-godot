extends Node
## Spawns the journal overlay anywhere in the game. Lives outside the per-scene
## tree so it survives travel. Two ways to open:
##   - Real player presses J → _unhandled_input catches the InputEvent.
##   - Driver / scripted code calls open() directly.

const JOURNAL_SCENE: PackedScene = preload("res://src/scenes/journal/journal.tscn")

var _open_overlay: Node = null


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("open_journal"):
		return
	open()


func open() -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if _open_overlay != null and is_instance_valid(_open_overlay):
		return
	_open_overlay = JOURNAL_SCENE.instantiate()
	get_tree().root.add_child(_open_overlay)
	_open_overlay.tree_exited.connect(_on_overlay_closed)
	if SfxBank:
		SfxBank.play("journal_open")


func is_open() -> bool:
	return _open_overlay != null and is_instance_valid(_open_overlay)


func close() -> void:
	if not is_open():
		return
	if _open_overlay.has_method("close"):
		_open_overlay.close()
	else:
		_open_overlay.queue_free()


func _on_overlay_closed() -> void:
	_open_overlay = null
