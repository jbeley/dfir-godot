extends CharacterBody2D
## Player character in the top-down WFH office. WASD/stick movement, interact with hotspots.

@export var speed: float = 60.0

var nearby_interactable: Node2D = null
var is_at_workstation: bool = false

signal interacted_with(target: Node2D)


func _physics_process(_delta: float) -> void:
	if is_at_workstation:
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and nearby_interactable:
		interacted_with.emit(nearby_interactable)


func set_nearby_interactable(target: Node2D) -> void:
	nearby_interactable = target


func clear_nearby_interactable(target: Node2D) -> void:
	if nearby_interactable == target:
		nearby_interactable = null
