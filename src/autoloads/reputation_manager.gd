extends Node
## Tracks player reputation, career progression, and the three WFH stats.

## Career tiers - 7 levels from Intern to Director
enum CareerTier {
	INTERN,           # 0 - Guided tutorials, basic tools
	JUNIOR_ANALYST,   # 1 - Simple cases, mentor available
	ANALYST,          # 2 - Medium cases, less guidance
	SENIOR_ANALYST,   # 3 - Complex cases, open sandbox
	PRINCIPAL,        # 4 - Expert cases, all tools unlocked
	TEAM_LEAD,        # 5 - Manage junior NPCs, strategic decisions
	DIRECTOR,         # 6 - Run the firm, hardest escalations
}

const TIER_NAMES: Array[String] = [
	"Intern",
	"Junior Analyst",
	"Analyst",
	"Senior Analyst",
	"Principal Analyst",
	"Team Lead",
	"Director",
]

## Reputation thresholds for each tier
const TIER_THRESHOLDS: Array[float] = [0.0, 15.0, 30.0, 50.0, 70.0, 85.0, 95.0]

var reputation: float = 0.0  # 0-100 scale
var career_tier: int = CareerTier.INTERN

## WFH Stats (0-100 each)
var focus: float = 100.0    # Affects investigation accuracy
var energy: float = 100.0   # Affects processing speed
var stress: float = 0.0     # Affects everything negatively

## Lifetime stats
var total_cases_completed: int = 0
var total_cases_failed: int = 0

signal reputation_changed(old_val: float, new_val: float)
signal career_tier_changed(old_tier: int, new_tier: int)
signal stats_changed
signal promoted(new_tier: int, tier_name: String)


func adjust_reputation(amount: float) -> void:
	var old := reputation
	reputation = clampf(reputation + amount, 0.0, 100.0)
	if old != reputation:
		reputation_changed.emit(old, reputation)
		_check_tier_change()


func _check_tier_change() -> void:
	var new_tier := CareerTier.INTERN
	for i in range(TIER_THRESHOLDS.size() - 1, -1, -1):
		if reputation >= TIER_THRESHOLDS[i]:
			new_tier = i
			break

	if new_tier != career_tier:
		var old_tier := career_tier
		career_tier = new_tier
		career_tier_changed.emit(old_tier, new_tier)
		if new_tier > old_tier:
			promoted.emit(new_tier, TIER_NAMES[new_tier])


func get_tier_name() -> String:
	return TIER_NAMES[career_tier]


## Apply stat changes from activities
func drink_coffee() -> void:
	energy = minf(energy + 20.0, 100.0)
	stress = maxf(stress - 5.0, 0.0)
	stats_changed.emit()


func sleep() -> void:
	energy = 100.0
	focus = minf(focus + 30.0, 100.0)
	stress = maxf(stress - 20.0, 0.0)
	stats_changed.emit()


func exercise() -> void:
	focus = minf(focus + 15.0, 100.0)
	energy = maxf(energy - 10.0, 0.0)
	stress = maxf(stress - 15.0, 0.0)
	stats_changed.emit()


func pet_cat() -> void:
	stress = maxf(stress - 10.0, 0.0)
	focus = minf(focus + 5.0, 100.0)
	stats_changed.emit()


func work_drain(minutes: float) -> void:
	## Called by TimeManager as time passes while working
	var drain_rate := 0.1 * (1.0 + stress / 100.0)  # Stress makes drain faster
	focus = maxf(focus - drain_rate * minutes, 0.0)
	energy = maxf(energy - drain_rate * 0.5 * minutes, 0.0)
	stress = minf(stress + drain_rate * 0.2 * minutes, 100.0)
	stats_changed.emit()


## Get a performance multiplier based on current stats (0.5 - 1.5)
func get_performance_multiplier() -> float:
	var focus_mod := remap(focus, 0.0, 100.0, 0.7, 1.2)
	var energy_mod := remap(energy, 0.0, 100.0, 0.8, 1.1)
	var stress_mod := remap(stress, 0.0, 100.0, 1.2, 0.7)
	return clampf(focus_mod * energy_mod * stress_mod, 0.5, 1.5)


## Check if the player is burned out
func is_burned_out() -> bool:
	return energy <= 5.0 and stress >= 90.0
