extends CanvasLayer
## On-screen touch controls for mobile. Virtual joystick + action buttons.
## Auto-shows on touch devices, hidden on desktop.

var _joystick_center := Vector2.ZERO
var _joystick_touching := false
var _joystick_touch_index := -1
var _joystick_vector := Vector2.ZERO

const JOYSTICK_RADIUS := 30.0
const JOYSTICK_DEAD_ZONE := 0.15

@onready var joystick_bg: Control = $JoystickBG
@onready var joystick_knob: Control = $JoystickBG/Knob
@onready var btn_interact: Button = $BtnInteract
@onready var btn_pause: Button = $BtnPause


func _ready() -> void:
	layer = 50
	# Only show on touch/mobile
	var is_mobile := _detect_mobile()
	visible = is_mobile

	if is_mobile:
		btn_interact.pressed.connect(_on_interact)
		btn_pause.pressed.connect(_on_pause)


func _detect_mobile() -> bool:
	# In web builds, check if it's a touch device
	if OS.has_feature("web"):
		return DisplayServer.is_touchscreen_available()
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		# Check if touch is in the joystick area (left half of screen)
		if touch.position.x < get_viewport().get_visible_rect().size.x * 0.4:
			if touch.pressed:
				_joystick_touching = true
				_joystick_touch_index = touch.index
				_joystick_center = joystick_bg.global_position + joystick_bg.size / 2.0
			elif touch.index == _joystick_touch_index:
				_joystick_touching = false
				_joystick_touch_index = -1
				_joystick_vector = Vector2.ZERO
				joystick_knob.position = joystick_bg.size / 2.0 - joystick_knob.size / 2.0
				_update_input()

	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _joystick_touch_index and _joystick_touching:
			var delta := drag.position - _joystick_center
			var distance := delta.length()
			if distance > JOYSTICK_RADIUS:
				delta = delta.normalized() * JOYSTICK_RADIUS

			_joystick_vector = delta / JOYSTICK_RADIUS
			if _joystick_vector.length() < JOYSTICK_DEAD_ZONE:
				_joystick_vector = Vector2.ZERO

			# Move knob visual
			joystick_knob.position = joystick_bg.size / 2.0 - joystick_knob.size / 2.0 + delta

			_update_input()


func _update_input() -> void:
	# Emit movement input actions
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")

	if _joystick_vector.x < -JOYSTICK_DEAD_ZONE:
		Input.action_press("move_left", -_joystick_vector.x)
	elif _joystick_vector.x > JOYSTICK_DEAD_ZONE:
		Input.action_press("move_right", _joystick_vector.x)

	if _joystick_vector.y < -JOYSTICK_DEAD_ZONE:
		Input.action_press("move_up", -_joystick_vector.y)
	elif _joystick_vector.y > JOYSTICK_DEAD_ZONE:
		Input.action_press("move_down", _joystick_vector.y)


func _on_interact() -> void:
	Input.action_press("interact")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("interact")


func _on_pause() -> void:
	Input.action_press("pause_game")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("pause_game")
