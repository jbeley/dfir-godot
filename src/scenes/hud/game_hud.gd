extends CanvasLayer
## Persistent HUD overlay showing clock, stats, case count, and notifications.

@onready var clock_label: Label = %ClockLabel
@onready var day_label: Label = %DayLabel
@onready var case_count_label: Label = %CaseCountLabel
@onready var stats_label: Label = %StatsLabel
@onready var notification_label: Label = %NotificationLabel

var _notification_timer: float = 0.0


func _ready() -> void:
	TimeManager.minute_changed.connect(_on_time_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	CaseManager.case_received.connect(_on_case_received)
	CaseManager.case_deadline_warning.connect(_on_deadline_warning)
	ReputationManager.stats_changed.connect(_update_stats)
	ReputationManager.promoted.connect(_on_promoted)
	notification_label.visible = false
	_update_all()


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
