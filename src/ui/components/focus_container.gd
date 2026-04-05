class_name FocusContainer
extends VBoxContainer
## Automatically sets up focus neighbors for all child controls.
## Makes gamepad navigation just work for vertical lists of buttons/controls.

@export var wrap_focus: bool = true


func _ready() -> void:
	child_entered_tree.connect(_on_child_changed)
	child_exiting_tree.connect(_on_child_changed)
	call_deferred("_setup_focus")


func _on_child_changed(_node: Node) -> void:
	call_deferred("_setup_focus")


func _setup_focus() -> void:
	var focusable: Array[Control] = []
	for child in get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			focusable.append(child as Control)

	if focusable.is_empty():
		return

	for i in range(focusable.size()):
		var ctrl := focusable[i]
		# Set up/down neighbors
		if i > 0:
			ctrl.focus_neighbor_top = focusable[i - 1].get_path()
		if i < focusable.size() - 1:
			ctrl.focus_neighbor_bottom = focusable[i + 1].get_path()

	# Wrap around
	if wrap_focus and focusable.size() > 1:
		focusable[0].focus_neighbor_top = focusable[-1].get_path()
		focusable[-1].focus_neighbor_bottom = focusable[0].get_path()
