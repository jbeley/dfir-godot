extends CharacterBody2D
## Player character in the top-down WFH office. WASD/stick movement, interact with hotspots.
## Spritesheet: 4 columns (walk frames) x 4 rows (down, left, right, up).

@export var speed: float = 60.0

@onready var sprite: Sprite2D = $Sprite

var nearby_interactable: Node2D = null
var is_at_workstation: bool = false

var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _facing: int = 0  # 0=down, 1=left, 2=right, 3=up

signal interacted_with(target: Node2D)


func _physics_process(delta: float) -> void:
	if is_at_workstation:
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()

	# Update animation
	if input_dir.length() > 0.1:
		# Determine facing direction
		if absf(input_dir.x) > absf(input_dir.y):
			_facing = 1 if input_dir.x < 0 else 2
		else:
			_facing = 3 if input_dir.y < 0 else 0

		# Advance walk cycle
		_anim_timer += delta
		if _anim_timer > 0.15:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % 4
	else:
		# Idle - use frame 0
		_anim_frame = 0
		_anim_timer = 0.0

	if sprite:
		sprite.frame = _facing * 4 + _anim_frame


var _interact_cooldown: float = 0.0

func _process(delta: float) -> void:
	if _interact_cooldown > 0:
		_interact_cooldown -= delta
	# Poll for interact action (works with both keyboard and touch Input.action_press)
	if Input.is_action_just_pressed("interact") and nearby_interactable and _interact_cooldown <= 0:
		_interact_cooldown = 0.5
		interacted_with.emit(nearby_interactable)


func set_nearby_interactable(target: Node2D) -> void:
	nearby_interactable = target


func clear_nearby_interactable(target: Node2D) -> void:
	if nearby_interactable == target:
		nearby_interactable = null
