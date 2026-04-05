extends Node
## In-game clock system. Tracks day, hour, minute. Drives day/night cycle and deadlines.
## Default: 1 real second = 5 game minutes (a full 24h day = ~5 real minutes).

var game_minutes_per_second: float = 5.0
var current_day: int = 1
var current_hour: int = 8  # Start at 8 AM
var current_minute: int = 0
var paused: bool = false

var _accumulated_time: float = 0.0

signal minute_changed(minute: int)
signal hour_changed(hour: int)
signal day_changed(day: int)
signal time_of_day_changed(period: String)  # "morning", "afternoon", "evening", "night"
signal deadline_warning(case_id: String, hours_remaining: int)


func _process(delta: float) -> void:
	if paused or GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_accumulated_time += delta * game_minutes_per_second
	while _accumulated_time >= 1.0:
		_accumulated_time -= 1.0
		_advance_minute()


func _advance_minute() -> void:
	current_minute += 1
	minute_changed.emit(current_minute)

	if current_minute >= 60:
		current_minute = 0
		_advance_hour()


func _advance_hour() -> void:
	var old_period := get_time_period()
	current_hour += 1
	hour_changed.emit(current_hour)

	if current_hour >= 24:
		current_hour = 0
		_advance_day()

	var new_period := get_time_period()
	if old_period != new_period:
		time_of_day_changed.emit(new_period)


func _advance_day() -> void:
	current_day += 1
	day_changed.emit(current_day)


func get_time_period() -> String:
	if current_hour >= 6 and current_hour < 12:
		return "morning"
	elif current_hour >= 12 and current_hour < 17:
		return "afternoon"
	elif current_hour >= 17 and current_hour < 22:
		return "evening"
	else:
		return "night"


func get_time_string() -> String:
	var ampm := "AM" if current_hour < 12 else "PM"
	var display_hour := current_hour % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, current_minute, ampm]


func get_day_string() -> String:
	return "Day %d" % current_day


## Get total elapsed game hours (for deadline calculations).
func get_total_hours() -> float:
	return (current_day - 1) * 24.0 + current_hour + current_minute / 60.0


## Get a darkness value for day/night cycle (0.0 = full day, 1.0 = full night).
func get_darkness() -> float:
	var hour_f := current_hour + current_minute / 60.0
	if hour_f >= 7.0 and hour_f <= 18.0:
		return 0.0  # Full daylight
	elif hour_f >= 22.0 or hour_f <= 4.0:
		return 0.7  # Night (not pitch black - we're indoors)
	elif hour_f > 18.0 and hour_f < 22.0:
		return remap(hour_f, 18.0, 22.0, 0.0, 0.7)  # Dusk
	else:
		return remap(hour_f, 4.0, 7.0, 0.7, 0.0)  # Dawn
