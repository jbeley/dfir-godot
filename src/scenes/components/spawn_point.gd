extends Marker2D
class_name SpawnPoint

## Marks a position where the player can be placed when entering a scene.
## WorldScene matches WorldManager.consume_spawn_id() against `id` to pick one.

@export var id: StringName = &"default"
