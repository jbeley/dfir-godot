extends CanvasLayer
## Floating toast notifications anchored to the bottom-right of the viewport.
## Survives scene transitions because it lives at /root as an autoload.
## Listens to JournalManager / HeatManager / WorldManager for events the
## player should know about and renders a stack of fading messages.

const MAX_VISIBLE: int = 3
const TOAST_LIFETIME: float = 4.0
const FADE_OUT: float = 0.6
const SLOT_HEIGHT: float = 22.0
const SLOT_TOP_MARGIN: float = 40.0
const SLOT_RIGHT_MARGIN: float = 8.0
const SLOT_WIDTH: float = 320.0

var _toasts: Array[Dictionary] = []
var _container: Control


func _ready() -> void:
	# Above the HUD (layer=10) so toasts read on top of game world, but below
	# LorePopup (50) and Journal (60) so modals always cover them cleanly.
	layer = 15
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	# Connect signals at runtime so this script loads cleanly even if some
	# autoloads are missing in test harnesses.
	_connect_if_present("/root/JournalManager", "location_visited",
		_on_journal_location_visited)
	_connect_if_present("/root/JournalManager", "secret_found",
		_on_journal_secret_found)
	_connect_if_present("/root/JournalManager", "npc_met",
		_on_journal_npc_met)
	_connect_if_present("/root/JournalManager", "rumor_heard",
		_on_journal_rumor_heard)
	_connect_if_present("/root/JournalManager", "faction_interaction",
		_on_journal_faction_interaction)
	_connect_if_present("/root/HeatManager", "heat_threshold_crossed",
		_on_heat_threshold_crossed)


func show_toast(text: String, kind: String = "info") -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.12, 0.85)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(bg)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_color_override("font_color", _color_for_kind(kind))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(label)

	var entry: Dictionary = {
		"bg": bg,
		"label": label,
		"created_at": Time.get_unix_time_from_system(),
	}
	_toasts.append(entry)
	if _toasts.size() > MAX_VISIBLE:
		_dismiss(_toasts.front())
	_layout()


func _process(_delta: float) -> void:
	if _toasts.is_empty():
		return
	var now: float = Time.get_unix_time_from_system()
	var dead: Array[Dictionary] = []
	for entry: Dictionary in _toasts:
		var age: float = now - float(entry["created_at"])
		if age > TOAST_LIFETIME:
			dead.append(entry)
		else:
			var fade_start: float = TOAST_LIFETIME - FADE_OUT
			var alpha: float = 1.0
			if age > fade_start:
				alpha = clampf(1.0 - (age - fade_start) / FADE_OUT, 0.0, 1.0)
			var label: Label = entry["label"] as Label
			var bg: ColorRect = entry["bg"] as ColorRect
			if label and is_instance_valid(label):
				label.modulate.a = alpha
			if bg and is_instance_valid(bg):
				bg.modulate.a = alpha
	for entry: Dictionary in dead:
		_dismiss(entry)


func _dismiss(entry: Dictionary) -> void:
	for key: String in ["label", "bg"]:
		var node: Node = entry.get(key, null) as Node
		if node and is_instance_valid(node):
			node.queue_free()
	_toasts.erase(entry)
	_layout()


func _layout() -> void:
	# Stack toasts from the top-right downward, newest at the top.
	var i: int = 0
	for entry: Dictionary in _toasts:
		var label: Label = entry["label"] as Label
		var bg: ColorRect = entry["bg"] as ColorRect
		if label == null or not is_instance_valid(label):
			continue
		var top: float = SLOT_TOP_MARGIN + SLOT_HEIGHT * float(_toasts.size() - 1 - i)
		# Anchor to top-right so it follows the viewport size.
		for n: Control in [label, bg]:
			n.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			n.offset_left = -SLOT_WIDTH - SLOT_RIGHT_MARGIN
			n.offset_right = -SLOT_RIGHT_MARGIN
			n.offset_top = top
			n.offset_bottom = top + SLOT_HEIGHT
		i += 1


func _color_for_kind(kind: String) -> Color:
	match kind:
		"discovery":
			return Color(1.0, 0.92, 0.55)
		"warning":
			return Color(1.0, 0.55, 0.45)
		"faction":
			return Color(0.85, 0.7, 1.0)
		"info", _:
			return Color(0.85, 0.95, 1.0)


func _connect_if_present(autoload_path: String, signal_name: String, target: Callable) -> void:
	var node: Node = get_node_or_null(autoload_path)
	if node and node.has_signal(signal_name):
		node.connect(signal_name, target)


# --- Signal handlers ---


func _on_journal_location_visited(location_id: StringName) -> void:
	# Only toast new visits — repeat visits would be noisy.
	var jm: Node = get_node_or_null("/root/JournalManager")
	if jm == null:
		return
	var visits: Dictionary = jm.get_locations_visited()
	if int(visits.get(location_id, 0)) > 1:
		return
	var loc_name: String = String(location_id)
	var wm: Node = get_node_or_null("/root/WorldManager")
	if wm:
		var loc: Resource = wm.get_location(location_id)
		if loc:
			loc_name = loc.display_name
	show_toast("Discovered: %s" % loc_name, "discovery")
	_play("location_arrived")
	_maybe_first_journal_hint(location_id)


func _maybe_first_journal_hint(location_id: StringName) -> void:
	# When the player first leaves the apartment for *anywhere* else, surface
	# the J keybind so they know the journal exists.
	if location_id == &"apartment":
		return
	if _journal_hint_shown():
		return
	_remember_journal_hint_shown()
	# Slight delay so it lands after the "Discovered" toast.
	await get_tree().create_timer(1.4, true).timeout
	show_toast("Tip: press [J] to open your journal anywhere", "info")


func _journal_hint_shown() -> bool:
	return _persistent_flag("journal_hint_shown")


func _remember_journal_hint_shown() -> void:
	_set_persistent_flag("journal_hint_shown", true)


const _FLAG_PATH: String = "user://saves/ui_flags.json"


func _persistent_flag(key: String) -> bool:
	if not FileAccess.file_exists(_FLAG_PATH):
		return false
	var f: FileAccess = FileAccess.open(_FLAG_PATH, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		return bool(data.get(key, false))
	return false


func _set_persistent_flag(key: String, value: bool) -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	var data: Dictionary = {}
	if FileAccess.file_exists(_FLAG_PATH):
		var fr: FileAccess = FileAccess.open(_FLAG_PATH, FileAccess.READ)
		if fr:
			var parsed: Variant = JSON.parse_string(fr.get_as_text())
			fr.close()
			if parsed is Dictionary:
				data = parsed
	data[key] = value
	var fw: FileAccess = FileAccess.open(_FLAG_PATH, FileAccess.WRITE)
	if fw:
		fw.store_string(JSON.stringify(data))
		fw.close()


func _on_journal_secret_found(_secret_id: StringName) -> void:
	show_toast("Secret found", "discovery")
	_play("secret_found")


func _on_journal_npc_met(npc_id: StringName) -> void:
	var jm: Node = get_node_or_null("/root/JournalManager")
	if jm == null:
		return
	var npcs: Dictionary = jm.get_npcs_met()
	var entry: Dictionary = npcs.get(npc_id, {})
	var name: String = String(entry.get("display_name", String(npc_id)))
	var arch: String = String(entry.get("archetype", ""))
	show_toast("Met: %s [%s]" % [name, arch], "discovery")


func _on_journal_rumor_heard(_rumor_id: StringName) -> void:
	show_toast("Rumor noted", "info")


func _on_journal_faction_interaction(faction_id: StringName, delta: int) -> void:
	if delta == 0:
		return
	var sign: String = "+" if delta > 0 else ""
	show_toast("Faction %s: %s%d" % [String(faction_id), sign, delta], "faction")


func _on_heat_threshold_crossed(faction_id: StringName, threshold: float) -> void:
	show_toast(
		"Heat rising — %s noticed you (%.0f)" % [String(faction_id), threshold],
		"warning"
	)
	_play("heat_warning")


func _play(sfx_id: String) -> void:
	var bank: Node = get_node_or_null("/root/SfxBank")
	if bank and bank.has_method("play"):
		bank.play(sfx_id)
