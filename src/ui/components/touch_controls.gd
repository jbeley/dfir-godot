extends CanvasLayer
## On-screen touch controls for mobile/tablet.
## Virtual joystick (left) + action buttons (right).
## Always visible on web builds to support touchscreen laptops and phones.

var _joystick_center := Vector2.ZERO
var _joystick_touching := false
var _joystick_touch_index := -1
var _joystick_vector := Vector2.ZERO
var _is_touch_active := false

const JOYSTICK_RADIUS := 35.0
const JOYSTICK_DEAD_ZONE := 0.12


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Show on mobile, web, or any touch device
	_is_touch_active = _should_show()

	# Always connect buttons (they're just hidden on desktop)
	$BtnInteract.pressed.connect(_on_interact)
	$BtnPause.pressed.connect(_on_pause)
	$BtnBack.pressed.connect(_on_back)

	_update_visibility()

	# Listen for touch events to auto-show
	if not _is_touch_active:
		set_process_input(true)


func _should_show() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if OS.has_feature("web"):
		# Always show on web - many users on phones/tablets
		return true
	return DisplayServer.is_touchscreen_available()


func _input(event: InputEvent) -> void:
	# Auto-show on first touch event
	if not _is_touch_active and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		_is_touch_active = true
		_update_visibility()

	if not _is_touch_active:
		return

	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		var vp_size := get_viewport().get_visible_rect().size
		# Joystick area: left 40% of screen
		if touch.position.x < vp_size.x * 0.4 and touch.position.y > vp_size.y * 0.4:
			if touch.pressed:
				_joystick_touching = true
				_joystick_touch_index = touch.index
				_joystick_center = $JoystickBG.global_position + $JoystickBG.size / 2.0
			elif touch.index == _joystick_touch_index:
				_stop_joystick()

	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _joystick_touch_index and _joystick_touching:
			var delta := drag.position - _joystick_center
			if delta.length() > JOYSTICK_RADIUS:
				delta = delta.normalized() * JOYSTICK_RADIUS

			_joystick_vector = delta / JOYSTICK_RADIUS
			if _joystick_vector.length() < JOYSTICK_DEAD_ZONE:
				_joystick_vector = Vector2.ZERO

			$JoystickBG/Knob.position = $JoystickBG.size / 2.0 - $JoystickBG/Knob.size / 2.0 + delta
			_update_movement()


func _stop_joystick() -> void:
	_joystick_touching = false
	_joystick_touch_index = -1
	_joystick_vector = Vector2.ZERO
	$JoystickBG/Knob.position = $JoystickBG.size / 2.0 - $JoystickBG/Knob.size / 2.0
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")


func _update_movement() -> void:
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


func _update_visibility() -> void:
	$JoystickBG.visible = _is_touch_active
	$BtnInteract.visible = _is_touch_active
	$BtnPause.visible = _is_touch_active
	$BtnBack.visible = _is_touch_active


func _on_interact() -> void:
	Input.action_press("interact")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("interact")


func _on_pause() -> void:
	Input.action_press("pause_game")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("pause_game")


func _on_back() -> void:
	# Universal back: return to office from any scene
	var current := get_tree().current_scene
	if current and current.scene_file_path != "res://src/scenes/office/office.tscn":
		GameManager.change_scene("res://src/scenes/office/office.tscn")
