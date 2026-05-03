extends Area2D
class_name Door

## Interactable door. On interact(), travels to `target_location` spawning the
## player at `target_spawn`. Add a CollisionShape2D child to size the trigger.
##
## Usage in a scene: instance Door, set the two ids, and put it in the
## "hotspots" group so the world scene picks it up for prompts.

@export var target_location: StringName = &""
@export var target_spawn: StringName = &"default"
@export var prompt: String = "[E] Enter"
@export var sprite_texture: Texture2D


func _ready() -> void:
	add_to_group("hotspots")
	const DoorSpriteRegistry := preload("res://src/systems/world/door_sprite_registry.gd")
	var tex: Texture2D = sprite_texture
	if tex == null and target_location != &"":
		tex = DoorSpriteRegistry.sprite_for_target(target_location)
	var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D
	if sprite and tex != null:
		sprite.texture = tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var placeholder: ColorRect = get_node_or_null("Placeholder") as ColorRect
		if placeholder:
			placeholder.visible = false


func get_prompt() -> String:
	return prompt


func interact() -> void:
	if target_location == &"":
		push_warning("Door at %s has no target_location" % get_path())
		return
	WorldManager.travel_to(target_location, target_spawn)
