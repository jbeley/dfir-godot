extends Camera2D
class_name WorldCamera

## Top-down follow camera for world scenes larger than the 480x270 viewport.
## Set limit_* in the scene to clamp scrolling at the map edges.

@export var follow_target_path: NodePath
@export var smoothing: float = 5.0

var _target: Node2D


func _ready() -> void:
	if follow_target_path != NodePath():
		_target = get_node_or_null(follow_target_path) as Node2D
	position_smoothing_enabled = true
	position_smoothing_speed = smoothing
	make_current()


func set_target(target: Node2D) -> void:
	_target = target


func _process(_delta: float) -> void:
	if _target and is_instance_valid(_target):
		global_position = _target.global_position
