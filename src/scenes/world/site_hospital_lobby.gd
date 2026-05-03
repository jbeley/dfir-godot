extends "res://src/scenes/components/world_scene.gd"

## St. Catherine's Regional Medical Center — front lobby. Marcie returns
## here, with new dialogue that acknowledges Acme. Doors lead to the street
## and to the nurse station.


func _ready() -> void:
	location_id = &"site_hospital_lobby"
	super._ready()
	var marcie: WorldNPC = get_node_or_null("Marcie") as WorldNPC
	if marcie != null:
		# Acknowledges the player from Acme. last_line in the journal updates
		# every interact, so the journal will always show her latest mood.
		marcie.lines = PackedStringArray([
			"You. Of course it's you. After Acme, every regional outfit with a rumor wants me consulting.",
			"The CFO called me at 3am. Twice. I am the office manager. It does not matter to him.",
			"Did Mike try the slow-grading line on you? He was in the parking lot here this morning. He's not now.",
		])
