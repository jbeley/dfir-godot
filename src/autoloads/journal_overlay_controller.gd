extends Node
## Listens for "open_journal" anywhere in the game and spawns the journal
## overlay. Lives outside the per-scene tree so it survives travel.

const JOURNAL_SCENE: PackedScene = preload("res://src/scenes/journal/journal.tscn")

var _open_overlay: Node = null


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("open_journal"):
		return
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	if _open_overlay != null and is_instance_valid(_open_overlay):
		return
	_open_overlay = JOURNAL_SCENE.instantiate()
	get_tree().root.add_child(_open_overlay)
	_open_overlay.tree_exited.connect(_on_overlay_closed)


func _on_overlay_closed() -> void:
	_open_overlay = null
