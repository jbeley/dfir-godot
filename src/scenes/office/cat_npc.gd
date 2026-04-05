extends Node2D
## The office cat. Wanders around, naps, sits on keyboard, demands attention.
## States: idle, walking, sleeping, keyboard, petted

enum CatState { IDLE, WALKING, SLEEPING, ON_KEYBOARD, PETTED }

@export var wander_speed: float = 20.0
@export var idle_time_min: float = 3.0
@export var idle_time_max: float = 8.0

@onready var sprite: Sprite2D = $Sprite

var state: CatState = CatState.IDLE
var _state_timer: float = 0.0
var _walk_target := Vector2.ZERO
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _facing_right := true

# Waypoints the cat can wander to
var waypoints: Array[Vector2] = [
	Vector2(300, 200),  # Cat bed
	Vector2(240, 160),  # Center (rug)
	Vector2(360, 85),   # Near desk
	Vector2(100, 180),  # Near coffee
	Vector2(200, 120),  # Middle of room
	Vector2(70, 200),   # Corner
	Vector2(400, 180),  # Near bookshelf
]

# Spritesheet layout: 4 cols x 6 rows (16x14 frames)
# Row 0: idle (2), Row 1: walk_right (4), Row 2: walk_left (4)
# Row 3: sleep (2), Row 4: keyboard (2), Row 5: petted (3)
const COLS := 4
const ANIM_IDLE := 0
const ANIM_WALK_R := 1
const ANIM_WALK_L := 2
const ANIM_SLEEP := 3
const ANIM_KEYBOARD := 4
const ANIM_PETTED := 5


func _ready() -> void:
	_enter_state(CatState.IDLE)


func _process(delta: float) -> void:
	_state_timer -= delta
	_anim_timer += delta

	match state:
		CatState.IDLE:
			_process_idle()
		CatState.WALKING:
			_process_walking(delta)
		CatState.SLEEPING:
			_process_sleeping()
		CatState.ON_KEYBOARD:
			_process_keyboard()
		CatState.PETTED:
			_process_petted()

	_update_animation()


func _process_idle() -> void:
	if _state_timer <= 0:
		# Decide what to do next
		var roll := randf()
		if roll < 0.5:
			_start_walking()
		elif roll < 0.7:
			_enter_state(CatState.SLEEPING)
			_state_timer = randf_range(10.0, 30.0)
		elif roll < 0.85:
			_enter_state(CatState.ON_KEYBOARD)
			_state_timer = randf_range(5.0, 15.0)
		else:
			# Stay idle a bit longer
			_state_timer = randf_range(idle_time_min, idle_time_max)


func _process_walking(delta: float) -> void:
	var dir := (_walk_target - position).normalized()
	position += dir * wander_speed * delta

	_facing_right = dir.x > 0

	if position.distance_to(_walk_target) < 3.0:
		position = _walk_target
		_enter_state(CatState.IDLE)
		_state_timer = randf_range(idle_time_min, idle_time_max)


func _process_sleeping() -> void:
	if _state_timer <= 0:
		_enter_state(CatState.IDLE)
		_state_timer = randf_range(2.0, 5.0)


func _process_keyboard() -> void:
	# Type random characters while on keyboard
	if _state_timer <= 0:
		_enter_state(CatState.IDLE)
		_state_timer = randf_range(3.0, 6.0)
		# Move away from desk
		_start_walking()


func _process_petted() -> void:
	if _state_timer <= 0:
		_enter_state(CatState.IDLE)
		_state_timer = randf_range(5.0, 10.0)


func pet() -> void:
	"""Called when the player interacts with the cat."""
	_enter_state(CatState.PETTED)
	_state_timer = 2.5


func _start_walking() -> void:
	_walk_target = waypoints[randi() % waypoints.size()]
	# Clamp to room bounds
	_walk_target.x = clampf(_walk_target.x, 30, 450)
	_walk_target.y = clampf(_walk_target.y, 50, 250)
	_enter_state(CatState.WALKING)


func _enter_state(new_state: CatState) -> void:
	state = new_state
	_anim_frame = 0
	_anim_timer = 0.0


func _update_animation() -> void:
	if not sprite:
		return

	var row := ANIM_IDLE
	var frame_count := 2
	var anim_speed := 0.5

	match state:
		CatState.IDLE:
			row = ANIM_IDLE
			frame_count = 2
			anim_speed = 0.8
		CatState.WALKING:
			row = ANIM_WALK_R if _facing_right else ANIM_WALK_L
			frame_count = 4
			anim_speed = 0.15
		CatState.SLEEPING:
			row = ANIM_SLEEP
			frame_count = 2
			anim_speed = 1.0
		CatState.ON_KEYBOARD:
			row = ANIM_KEYBOARD
			frame_count = 2
			anim_speed = 0.3
		CatState.PETTED:
			row = ANIM_PETTED
			frame_count = 3
			anim_speed = 0.4

	if _anim_timer >= anim_speed:
		_anim_timer = 0.0
		_anim_frame = (_anim_frame + 1) % frame_count

	sprite.frame = row * COLS + _anim_frame
