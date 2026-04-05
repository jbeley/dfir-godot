extends Node
## Generates random WFH interruptions that affect stats and gameplay.
## Interruptions fire based on time of day and probability.

signal interruption_triggered(interruption: Dictionary)

const INTERRUPTIONS := [
	{
		"id": "cat_keyboard",
		"text": "Your cat jumps on the keyboard and types 'asdfjkl;' into the terminal.",
		"icon": "cat",
		"focus_change": -5.0,
		"stress_change": -3.0,
		"energy_change": 0.0,
		"time_hours": [-1],  # Any time
		"weight": 15,
	},
	{
		"id": "cat_nap",
		"text": "Your cat falls asleep on your lap. It's very warm and cozy.",
		"icon": "cat",
		"focus_change": -8.0,
		"stress_change": -10.0,
		"energy_change": -3.0,
		"time_hours": [-1],
		"weight": 10,
	},
	{
		"id": "doorbell",
		"text": "Doorbell! It's a package delivery. You lose focus.",
		"icon": "home",
		"focus_change": -10.0,
		"stress_change": 2.0,
		"energy_change": -2.0,
		"time_hours": [10, 11, 12, 13, 14, 15, 16],
		"weight": 8,
	},
	{
		"id": "slack_ping",
		"text": "Slack: 'Hey, quick question...' It was not quick.",
		"icon": "work",
		"focus_change": -12.0,
		"stress_change": 5.0,
		"energy_change": -3.0,
		"time_hours": [9, 10, 11, 13, 14, 15, 16, 17],
		"weight": 20,
	},
	{
		"id": "meeting",
		"text": "Mandatory all-hands meeting. 45 minutes of your life you won't get back.",
		"icon": "work",
		"focus_change": -15.0,
		"stress_change": 8.0,
		"energy_change": -10.0,
		"time_hours": [10, 14, 15],
		"weight": 5,
	},
	{
		"id": "compliance_training",
		"text": "Reminder: Annual compliance training due today. You click through it.",
		"icon": "work",
		"focus_change": -8.0,
		"stress_change": 3.0,
		"energy_change": -5.0,
		"time_hours": [9, 10, 11],
		"weight": 3,
	},
	{
		"id": "coffee_spill",
		"text": "You spill coffee on your desk. Nothing important was damaged... this time.",
		"icon": "home",
		"focus_change": -5.0,
		"stress_change": 5.0,
		"energy_change": 0.0,
		"time_hours": [8, 9, 10],
		"weight": 5,
	},
	{
		"id": "isp_flicker",
		"text": "Internet connection drops for 30 seconds. Everything reconnects.",
		"icon": "tech",
		"focus_change": -8.0,
		"stress_change": 10.0,
		"energy_change": 0.0,
		"time_hours": [-1],
		"weight": 6,
	},
	{
		"id": "neighbor_noise",
		"text": "Your neighbor starts mowing the lawn. Focus dropping...",
		"icon": "home",
		"focus_change": -10.0,
		"stress_change": 5.0,
		"energy_change": 0.0,
		"time_hours": [10, 11, 12, 13, 14],
		"weight": 7,
	},
	{
		"id": "breaking_news",
		"text": "Breaking: New zero-day CVE dropped! Twitter is on fire. You resist doomscrolling.",
		"icon": "intel",
		"focus_change": -5.0,
		"stress_change": 3.0,
		"energy_change": 0.0,
		"time_hours": [-1],
		"weight": 8,
	},
	{
		"id": "power_flicker",
		"text": "Power flickers. UPS beeps. Everything stays on. Heart rate: elevated.",
		"icon": "tech",
		"focus_change": -3.0,
		"stress_change": 15.0,
		"energy_change": 0.0,
		"time_hours": [-1],
		"weight": 3,
	},
	{
		"id": "good_coffee",
		"text": "You brew the perfect cup of coffee. The aroma is incredible.",
		"icon": "positive",
		"focus_change": 5.0,
		"stress_change": -5.0,
		"energy_change": 10.0,
		"time_hours": [8, 9, 14],
		"weight": 8,
	},
	{
		"id": "mentor_tip",
		"text": "Senior analyst pings you: 'Pro tip: always check the scheduled tasks.'",
		"icon": "positive",
		"focus_change": 5.0,
		"stress_change": -3.0,
		"energy_change": 0.0,
		"time_hours": [9, 10, 11, 14, 15],
		"weight": 6,
	},
]

var _check_interval_minutes := 30  # Check for interruption every 30 game-minutes
var _minutes_since_check := 0
var _interruption_chance := 0.35  # 35% chance per check


func _ready() -> void:
	TimeManager.minute_changed.connect(_on_minute)


func _on_minute(_minute: int) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_minutes_since_check += 1
	if _minutes_since_check < _check_interval_minutes:
		return
	_minutes_since_check = 0

	if randf() > _interruption_chance:
		return

	var current_hour := TimeManager.current_hour
	var eligible: Array[Dictionary] = []
	var total_weight := 0

	for interruption: Dictionary in INTERRUPTIONS:
		var hours: Array = interruption.get("time_hours", [-1]) as Array
		if -1 in hours or current_hour in hours:
			eligible.append(interruption)
			total_weight += int(interruption.get("weight", 1))

	if eligible.is_empty():
		return

	# Weighted random selection
	var roll := randi() % total_weight
	var cumulative := 0
	for interruption: Dictionary in eligible:
		cumulative += int(interruption.get("weight", 1))
		if roll < cumulative:
			_trigger(interruption)
			return


func _trigger(interruption: Dictionary) -> void:
	# Apply stat changes
	ReputationManager.focus = clampf(
		ReputationManager.focus + float(interruption.get("focus_change", 0.0)), 0.0, 100.0)
	ReputationManager.energy = clampf(
		ReputationManager.energy + float(interruption.get("energy_change", 0.0)), 0.0, 100.0)
	ReputationManager.stress = clampf(
		ReputationManager.stress + float(interruption.get("stress_change", 0.0)), 0.0, 100.0)
	ReputationManager.stats_changed.emit()

	interruption_triggered.emit(interruption)
