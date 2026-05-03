extends "res://src/scenes/components/world_scene.gd"

## St. Catherine's — parking lot. The hospital chaplain (SECRET, gives lore on
## the surveillance), Devon the more-aggressive DarkLock recruiter (FACTION),
## and an escalated surveillance vehicle that bumps darklock heat by 18 — half
## again the Acme van's amount, signalling DarkLock is not bothering to hide.


func _ready() -> void:
	location_id = &"site_hospital_parking"
	super._ready()
	var chaplain: WorldNPC = get_node_or_null("Chaplain") as WorldNPC
	if chaplain != null:
		chaplain.lines = PackedStringArray([
			"I sit out here every shift. People come out to cry. They tell me things.",
			"The white SUV's been there four days. Two men. They take turns walking the perimeter.",
			"I am not going to call. But I am going to remember.",
		])
	var devon: WorldNPC = get_node_or_null("Devon") as WorldNPC
	if devon != null:
		devon.lines = PackedStringArray([
			"You're the consultant from Acme. I read the timeline. Real careful work.",
			"Same offer my colleague Mike made you. My rate is higher because the case is hotter.",
			"You won't say yes. They never do. But the offer stands. We'll see each other again.",
		])
