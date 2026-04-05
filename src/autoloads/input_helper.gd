extends Node
## Detects input device (gamepad vs keyboard+mouse) and provides focus helpers.

enum InputDevice { KEYBOARD_MOUSE, GAMEPAD }

var current_device: InputDevice = InputDevice.KEYBOARD_MOUSE

signal device_changed(device: InputDevice)


func _input(event: InputEvent) -> void:
	var new_device := current_device

	if event is InputEventKey or event is InputEventMouseMotion or event is InputEventMouseButton:
		new_device = InputDevice.KEYBOARD_MOUSE
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and absf(event.axis_value) < 0.5:
			return
		new_device = InputDevice.GAMEPAD

	if new_device != current_device:
		current_device = new_device
		device_changed.emit(current_device)
		_update_cursor_visibility()


func _update_cursor_visibility() -> void:
	if current_device == InputDevice.GAMEPAD:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func is_gamepad() -> bool:
	return current_device == InputDevice.GAMEPAD


func is_keyboard() -> bool:
	return current_device == InputDevice.KEYBOARD_MOUSE


## Grab focus on a control, useful for gamepad navigation after scene changes.
func grab_focus_on(control: Control) -> void:
	if control and is_gamepad():
		control.grab_focus()


## Set up focus neighbors for a list of controls (vertical layout).
func setup_vertical_focus(controls: Array[Control]) -> void:
	for i in range(controls.size()):
		var ctrl := controls[i]
		if i > 0:
			ctrl.focus_neighbor_top = controls[i - 1].get_path()
		if i < controls.size() - 1:
			ctrl.focus_neighbor_bottom = controls[i + 1].get_path()
	# Wrap around
	if controls.size() > 1:
		controls[0].focus_neighbor_top = controls[controls.size() - 1].get_path()
		controls[controls.size() - 1].focus_neighbor_bottom = controls[0].get_path()
