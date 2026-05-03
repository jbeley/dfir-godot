extends "res://src/scenes/components/world_scene.gd"

## St. Catherine's — nurse station. Dr. Asha Patel (RECURRING — will return
## in case 3) and Shawn the night-shift IT (FLAVOR) are here. Door connections
## go back to lobby and forward to server room and parking lot.


func _ready() -> void:
	location_id = &"site_hospital_nurse"
	super._ready()
	var asha: WorldNPC = get_node_or_null("DrPatel") as WorldNPC
	if asha != null:
		asha.lines = PackedStringArray([
			"I'm Asha Patel. CISO. Twenty-six beds, two campuses, budget for one third of a person.",
			"Patient charts went sideways at 04:11. Night charge nurse caught it because she still does paper rounds.",
			"If you talk to anyone here who matters, mention the audit log. The audit log.",
		])
	var shawn: WorldNPC = get_node_or_null("Shawn") as WorldNPC
	if shawn != null:
		shawn.lines = PackedStringArray([
			"Been here since 7pm yesterday. The Cisco rep is not picking up.",
			"Whoever did this kept the patient monitors running. So that's something.",
			"I have a kid. I am sleeping in the IT room tonight.",
		])
