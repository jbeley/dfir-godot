extends Node
## Self-driving playthrough robot. Activated only when `playthrough` is passed
## in the user-args (e.g. `godot ... -- playthrough`). Drives the player
## around with real Input.action_press events, captures screenshots after each
## checkpoint, and dumps final journal/heat/world state. Inert in normal play.

const SCREENSHOT_DIR: String = "user://playthrough/"
const NEAR_THRESHOLD: float = 6.0
const FRAME_TIMEOUT_SECS: float = 16.0

var _enabled: bool = false
var _shot_index: int = 0
var _movement_keys: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down"
]
var _failures: Array[String] = []
var _checks: Array[String] = []


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_enabled = args.has("playthrough")
	if not _enabled:
		return
	# Keep the driver ticking even when LorePopup pauses the tree.
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR)
	# Wait for autoloads + main menu to be alive, then start.
	await get_tree().create_timer(0.4, true).timeout
	await _run()


func _run() -> void:
	print("=== Playthrough start ===")
	# Skip main menu — go straight to the office.
	GameManager.change_scene("res://src/scenes/office/office.tscn")
	await GameManager.scene_transition_finished
	await get_tree().create_timer(0.5, true).timeout

	await _capture("apartment_arrival")

	# Walk to the front door and step out.
	await _door_step(Vector2(456, 240), "FrontDoor", &"street_downtown", "street_arrival")

	# Talk to the busker.
	await _interact_step(Vector2(440, 200), "FlavorNPC", "street_busker")
	_check("busker recorded as met", JournalManager.has_met_npc(&"street_busker"))

	# Find the lamppost sticker.
	await _interact_step(Vector2(620, 200), "HiddenSecret", "street_secret")
	_check("phrack sticker found", JournalManager.has_found_secret(&"streetlight_pattern"))

	# Enter Acme.
	await _door_step(Vector2(800, 178), "SiteDoor", &"site_acme_lobby", "acme_lobby")

	# Talk to Marcie.
	await _interact_step(Vector2(240, 130), "Marcie", "acme_marcie")
	_check(
		"marcie recorded as RECURRING",
		JournalManager.get_npcs_met().get(&"marcie_rivera", {}).get("archetype", "") == "RECURRING"
	)

	# Read the plaque.
	await _interact_step(Vector2(370, 60), "Plaque", "acme_plaque")
	_check(
		"best workplace plaque found",
		JournalManager.has_found_secret(&"acme_best_workplace_plaque")
	)

	# Move on to the cube farm.
	await _door_step(Vector2(440, 220), "CubesDoor", &"site_acme_cubes", "acme_cubes")

	# Phil panics.
	await _interact_step(Vector2(260, 95), "Phil", "acme_phil")
	_check(
		"phil recorded as FLAVOR",
		JournalManager.get_npcs_met().get(&"phil_garcia", {}).get("archetype", "") == "FLAVOR"
	)

	# Read the corkboard.
	await _interact_step(Vector2(370, 40), "Corkboard", "acme_corkboard")
	_check(
		"corkboard secret found",
		JournalManager.has_found_secret(&"acme_corkboard_passwords")
	)

	# Server closet.
	await _door_step(Vector2(320, 220), "ServerDoor", &"site_acme_server", "acme_server")

	# Reach behind the rack for the conficker sticky.
	await _interact_step(Vector2(105, 180), "StickyNote", "acme_conficker")
	_check("conficker sticky found", JournalManager.has_found_secret(&"conficker_sticky"))

	# Old Norton Ghost CD-ROM.
	await _interact_step(Vector2(410, 130), "GhostCD", "acme_ghost_cd")
	_check("norton ghost cd found", JournalManager.has_found_secret(&"norton_ghost_cdrom"))

	# Back to cubes, then alley.
	await _door_step(Vector2(40, 220), "CubesDoor", &"site_acme_cubes", "")
	await _door_step(Vector2(600, 220), "AlleyDoor", &"site_acme_alley", "acme_alley")

	# Janitor.
	await _interact_step(Vector2(120, 200), "Janitor", "acme_janitor")
	_check(
		"janitor recorded as SECRET",
		JournalManager.get_npcs_met().get(&"alley_janitor", {}).get("archetype", "") == "SECRET"
	)

	# Mike (faction recruit).
	await _interact_step(Vector2(380, 230), "Mike", "acme_mike")
	_check(
		"mike recorded as FACTION",
		JournalManager.get_npcs_met().get(&"darklock_mike", {}).get("archetype", "") == "FACTION"
	)
	_check(
		"darklock standing increased",
		JournalManager.get_faction_standing(&"darklock") >= 1
	)

	# Spot the white van.
	await _interact_step(Vector2(240, 130), "WhiteVan", "acme_white_van")
	_check("darklock heat raised by van", HeatManager.get_heat(&"darklock") > 0.0)
	_check("van rumor recorded", JournalManager.get_rumors_heard().has(&"acme_alley_van"))
	var heat_after_acme: float = HeatManager.get_heat(&"darklock")

	# Out of Acme via alley -> cubes -> lobby -> street.
	await _door_step(Vector2(40, 230), "CubesDoor", &"site_acme_cubes", "")
	await _door_step(Vector2(40, 220), "LobbyDoor", &"site_acme_lobby", "")
	await _door_step(Vector2(40, 220), "StreetDoor", &"street_downtown", "back_on_street")

	# Walk further down the block to the hospital.
	await _door_step(Vector2(1120, 178), "HospitalDoor", &"site_hospital_lobby", "hospital_lobby")

	# Marcie is back. Verify the recurring-NPC promise: same npc_id, fresh
	# dialogue, journal still has only one entry for her.
	await _interact_step(Vector2(240, 130), "Marcie", "hospital_marcie_returns")
	_check(
		"marcie still recorded as RECURRING after second meet",
		JournalManager.get_npcs_met().get(&"marcie_rivera", {}).get("archetype", "") == "RECURRING"
	)
	_check(
		"marcie's last_line updated to hospital opener",
		String(JournalManager.get_npcs_met().get(&"marcie_rivera", {}).get("last_line", "")).begins_with("You. Of course")
	)

	# HIPAA trophy in lobby.
	await _interact_step(Vector2(370, 60), "Plaque", "hospital_hipaa_trophy")
	_check("hipaa trophy found", JournalManager.has_found_secret(&"hospital_hipaa_trophy"))

	# Into the wards. Meet Dr. Patel and Shawn.
	await _door_step(Vector2(440, 220), "NurseDoor", &"site_hospital_nurse", "hospital_nurse")

	await _interact_step(Vector2(220, 130), "DrPatel", "hospital_dr_patel")
	_check(
		"dr patel recorded as RECURRING",
		JournalManager.get_npcs_met().get(&"asha_patel", {}).get("archetype", "") == "RECURRING"
	)

	await _interact_step(Vector2(420, 140), "Shawn", "hospital_shawn")
	_check(
		"shawn recorded as FLAVOR",
		JournalManager.get_npcs_met().get(&"shawn_it", {}).get("archetype", "") == "FLAVOR"
	)

	await _interact_step(Vector2(360, 35), "Clipboard", "hospital_clipboard")
	_check("paper census secret found", JournalManager.has_found_secret(&"hospital_paper_census"))

	# IT room secrets.
	await _door_step(Vector2(320, 220), "ServerDoor", &"site_hospital_server", "hospital_server")

	await _interact_step(Vector2(230, 100), "TRSSecret", "hospital_trs80")
	_check("trs-80 secret found", JournalManager.has_found_secret(&"hospital_trs80_triage"))

	await _interact_step(Vector2(350, 175), "ChartSecret", "hospital_chart")
	_check("misfiled chart found", JournalManager.has_found_secret(&"hospital_misfiled_chart"))

	# Back to wards, then the parking lot for the surveillance escalation.
	await _door_step(Vector2(40, 220), "NurseDoor", &"site_hospital_nurse", "")
	await _door_step(Vector2(600, 220), "ParkingDoor", &"site_hospital_parking", "hospital_parking")

	await _interact_step(Vector2(120, 200), "Chaplain", "hospital_chaplain")
	_check(
		"chaplain recorded as SECRET",
		JournalManager.get_npcs_met().get(&"hospital_chaplain", {}).get("archetype", "") == "SECRET"
	)

	await _interact_step(Vector2(380, 235), "Devon", "hospital_devon")
	_check(
		"devon recorded as FACTION",
		JournalManager.get_npcs_met().get(&"darklock_devon", {}).get("archetype", "") == "FACTION"
	)
	_check(
		"darklock standing increased by devon",
		JournalManager.get_faction_standing(&"darklock") >= 2
	)

	# White SUV — heat should be strictly higher than after Acme van.
	await _interact_step(Vector2(240, 130), "WhiteSUV", "hospital_white_suv")
	_check("suv rumor recorded", JournalManager.get_rumors_heard().has(&"hospital_parking_suv"))
	_check(
		"darklock heat escalated past acme baseline",
		HeatManager.get_heat(&"darklock") > heat_after_acme
	)

	# Open the journal as the final visual; flip through the tabs.
	await _press_journal()
	await _capture("journal_locations")
	await _switch_journal_tab(1)
	await _capture("journal_npcs")
	await _switch_journal_tab(2)
	await _capture("journal_secrets")
	await _switch_journal_tab(3)
	await _capture("journal_rumors")
	await _switch_journal_tab(4)
	await _capture("journal_factions")
	await _dismiss_popup()

	# Dump state.
	_print_summary()
	_print_journal_dump()
	if _failures.is_empty():
		print("PLAYTHROUGH PASSED")
	else:
		print("PLAYTHROUGH FAILED")
		for f: String in _failures:
			print("  FAIL: " + f)
	get_tree().quit()


func _interact_step(target: Vector2, expected_node_name: String, label: String) -> void:
	## Walk to an interactable, press E, capture the popup, then dismiss it.
	await _walk_to(target)
	await _press_interact_at(expected_node_name)
	await _capture(label)
	await _dismiss_popup()


func _door_step(
	target: Vector2,
	expected_node_name: String,
	target_location: StringName,
	label: String
) -> void:
	## Walk to a door, press E, wait for the new scene, optionally capture.
	await _walk_to(target)
	await _press_interact_at(expected_node_name)
	await _wait_for_location(target_location)
	if label != "":
		await _capture(label)


func _walk_to(target: Vector2) -> void:
	var player: Node2D = _find_player()
	if player == null:
		_failures.append("walk_to: no player at scene %s" % _current_scene_name())
		return
	var deadline: float = Time.get_unix_time_from_system() + FRAME_TIMEOUT_SECS
	while is_instance_valid(player) and player.global_position.distance_to(target) > NEAR_THRESHOLD:
		_drive_movement(player.global_position, target)
		await get_tree().process_frame
		if Time.get_unix_time_from_system() > deadline:
			_failures.append(
				"walk_to(%s): timeout from %s in scene %s"
				% [target, player.global_position, _current_scene_name()]
			)
			break
	_release_movement()
	# Let the InteractArea catch up.
	await get_tree().process_frame
	await get_tree().process_frame


func _drive_movement(current: Vector2, target: Vector2) -> void:
	var dx: float = target.x - current.x
	var dy: float = target.y - current.y
	_set_action(&"move_left", dx < -2.0)
	_set_action(&"move_right", dx > 2.0)
	_set_action(&"move_up", dy < -2.0)
	_set_action(&"move_down", dy > 2.0)


func _release_movement() -> void:
	for k: StringName in _movement_keys:
		Input.action_release(k)


func _set_action(action: StringName, want_pressed: bool) -> void:
	if want_pressed and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not want_pressed and Input.is_action_pressed(action):
		Input.action_release(action)


func _press_interact_at(expected_node_name: String) -> void:
	var player: Node = _find_player()
	if player == null:
		_failures.append("press_interact: no player at %s" % _current_scene_name())
		return
	var nearby: Variant = player.get("nearby_interactable")
	var ok: bool = nearby != null and is_instance_valid(nearby) and nearby.name == expected_node_name
	_check(
		"near %s in %s" % [expected_node_name, _current_scene_name()],
		ok
	)
	Input.action_press(&"interact")
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_release(&"interact")
	# Run timer in pause-ignore mode so it ticks even if a LorePopup paused us.
	await get_tree().create_timer(0.5, true).timeout


func _press_journal() -> void:
	# Bypass the synthetic-input dance and open the overlay directly. Real
	# users still get the J keybind via JournalOverlayController._unhandled_input.
	JournalOverlayController.open()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3, true).timeout


func _dismiss_popup() -> void:
	## If a LorePopup is up, the tree is paused. Press interact to close it.
	if not _is_popup_open():
		return
	Input.action_press(&"ui_cancel")
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_release(&"ui_cancel")
	await get_tree().create_timer(0.25, true).timeout
	if _is_popup_open():
		# Fallback: directly close the popup if the input didn't reach it.
		_force_close_popups()
		await get_tree().create_timer(0.25, true).timeout


func _is_popup_open() -> bool:
	for child in get_tree().root.get_children():
		if child is LorePopup or child is JournalOverlay:
			return true
	var current: Node = get_tree().current_scene
	if current != null:
		for child in current.get_children():
			if child is LorePopup:
				return true
	return false


func _switch_journal_tab(index: int) -> void:
	for child in get_tree().root.get_children():
		if not (child is JournalOverlay):
			continue
		var tabs: TabContainer = child.find_child("Tabs", true, false) as TabContainer
		if tabs != null:
			tabs.current_tab = clampi(index, 0, tabs.get_tab_count() - 1)
			break
	await get_tree().process_frame
	await get_tree().create_timer(0.2, true).timeout


func _force_close_popups() -> void:
	for child in get_tree().root.get_children():
		if child is LorePopup or child is JournalOverlay:
			child.queue_free()
	var current: Node = get_tree().current_scene
	if current != null:
		for child in current.get_children():
			if child is LorePopup:
				child.queue_free()
	get_tree().paused = false


func _wait_for_location(location_id: StringName) -> void:
	var deadline: float = Time.get_unix_time_from_system() + FRAME_TIMEOUT_SECS
	while WorldManager.current_location_id != location_id:
		await get_tree().process_frame
		if Time.get_unix_time_from_system() > deadline:
			_failures.append("wait_for_location(%s): timeout, current=%s"
				% [location_id, WorldManager.current_location_id])
			return
	# Settle one extra frame so the scene's _ready has finished.
	await get_tree().create_timer(0.3).timeout


func _capture(label: String) -> void:
	_shot_index += 1
	var path: String = "%s%02d_%s.png" % [SCREENSHOT_DIR, _shot_index, label]
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var tex: ViewportTexture = viewport.get_texture()
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img == null:
		return
	img.save_png(path)
	print("  shot: %s" % path)


func _find_player() -> Node:
	var current: Node = get_tree().current_scene
	if current == null:
		return null
	return current.find_child("Player", true, false)


func _current_scene_name() -> String:
	var current: Node = get_tree().current_scene
	if current == null:
		return "<none>"
	return current.name


func _check(label: String, ok: bool) -> void:
	_checks.append("%s -> %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_failures.append(label)


func _print_summary() -> void:
	print("\n=== Checkpoint summary ===")
	for c: String in _checks:
		print("  " + c)


func _print_journal_dump() -> void:
	print("\n=== Final journal/heat/world state ===")
	print("World current_location_id = %s" % WorldManager.current_location_id)
	print("World discovered = %s" % str(WorldManager.discovered_locations))
	print("Locations visited = %s" % str(JournalManager.get_locations_visited()))
	print("NPCs met = %s" % str(JournalManager.get_npcs_met()))
	print("Secrets found = %d / %d"
		% [JournalManager.get_secrets_found_count(), JournalManager.get_secrets_known_count()])
	print("Rumors = %s" % str(JournalManager.get_rumors_heard()))
	print("Faction standing = %s" % str(JournalManager.get_all_faction_standings()))
	print("Heat = %s" % str(HeatManager.get_all_heat()))
