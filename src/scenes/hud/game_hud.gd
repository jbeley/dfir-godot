extends CanvasLayer
## Persistent HUD overlay showing clock, stats, case count, and notifications.

@onready var clock_label: Label = %ClockLabel
@onready var day_label: Label = %DayLabel
@onready var case_count_label: Label = %CaseCountLabel
@onready var stats_label: Label = %StatsLabel
@onready var notification_label: Label = %NotificationLabel
@onready var heat_label: Label = %HeatLabel

var _notification_timer: float = 0.0


func _ready() -> void:
	TimeManager.minute_changed.connect(_on_time_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	CaseManager.case_received.connect(_on_case_received)
	CaseManager.case_deadline_warning.connect(_on_deadline_warning)
	ReputationManager.stats_changed.connect(_update_stats)
	ReputationManager.promoted.connect(_on_promoted)
	if HeatManager and HeatManager.has_signal("heat_changed"):
		HeatManager.heat_changed.connect(_on_heat_changed)
	notification_label.visible = false
	_update_all()
	_update_heat()


func _process(delta: float) -> void:
	if _notification_timer > 0:
		_notification_timer -= delta
		if _notification_timer <= 0:
			notification_label.visible = false


func _on_time_changed(_minute: int) -> void:
	clock_label.text = TimeManager.get_time_string()


func _on_day_changed(_day: int) -> void:
	day_label.text = TimeManager.get_day_string()


func _on_case_received(_case_data: Resource) -> void:
	_update_case_count()
	_show_notification("New case received!")


func _on_deadline_warning(_case_data: Resource, hours_remaining: float) -> void:
	_show_notification("DEADLINE: %.0f hours remaining!" % hours_remaining)


func _on_promoted(_new_tier: int, tier_name: String) -> void:
	_show_notification("PROMOTED: %s!" % tier_name)


func _update_all() -> void:
	clock_label.text = TimeManager.get_time_string()
	day_label.text = TimeManager.get_day_string()
	_update_case_count()
	_update_stats()


func _update_case_count() -> void:
	var count := CaseManager.get_active_case_count()
	case_count_label.text = "Cases: %d" % count


func _update_stats() -> void:
	stats_label.text = "%s | Rep:%.0f | F:%.0f E:%.0f S:%.0f" % [
		ReputationManager.get_tier_name(),
		ReputationManager.reputation,
		ReputationManager.focus,
		ReputationManager.energy,
		ReputationManager.stress,
	]


func _show_notification(text: String, duration: float = 3.0) -> void:
	notification_label.text = text
	notification_label.visible = true
	_notification_timer = duration


func _on_heat_changed(_faction_id: StringName, _heat: float) -> void:
	_update_heat()


func _update_heat() -> void:
	if heat_label == null:
		return
	if HeatManager == null:
		heat_label.visible = false
		return
	var standings: Dictionary = HeatManager.get_all_heat()
	var parts: PackedStringArray = PackedStringArray()
	var hottest: float = 0.0
	for fid: Variant in standings:
		var amt: float = float(standings[fid])
		if amt <= 0.0:
			continue
		hottest = maxf(hottest, amt)
		parts.append("%s:%d" % [String(fid), int(amt)])
	if parts.is_empty():
		heat_label.visible = false
		return
	heat_label.visible = true
	heat_label.text = "Heat | " + " ".join(parts)
	# Tint warmer as heat climbs.
	var color: Color = Color(0.85, 0.85, 0.7)
	if hottest >= HeatManager.THRESHOLD_HOSTILE:
		color = Color(1.0, 0.45, 0.4)
	elif hottest >= HeatManager.THRESHOLD_NOTICED:
		color = Color(1.0, 0.75, 0.4)
	heat_label.add_theme_color_override("font_color", color)
