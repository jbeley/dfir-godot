extends Node
## Manages apartment visual upgrades based on career tier.
## Studio (Intern) -> 1BR (Analyst) -> House with office (Principal+)

enum ApartmentTier { STUDIO, ONE_BEDROOM, HOUSE }

var current_apartment: ApartmentTier = ApartmentTier.STUDIO

signal apartment_upgraded(new_tier: ApartmentTier)

# Tier thresholds match career progression
# Intern/Junior = Studio, Analyst/Senior = 1BR, Principal+ = House
const TIER_MAP := {
	0: ApartmentTier.STUDIO,      # Intern
	1: ApartmentTier.STUDIO,      # Junior
	2: ApartmentTier.ONE_BEDROOM, # Analyst
	3: ApartmentTier.ONE_BEDROOM, # Senior
	4: ApartmentTier.HOUSE,       # Principal
	5: ApartmentTier.HOUSE,       # Lead
	6: ApartmentTier.HOUSE,       # Director
}

const APARTMENT_NAMES := ["Studio Apartment", "One-Bedroom Apartment", "House with Home Office"]

# Visual configs for each apartment tier
const APARTMENT_CONFIGS := {
	ApartmentTier.STUDIO: {
		"floor_color": Color(0.22, 0.18, 0.15),
		"wall_color": Color(0.30, 0.28, 0.32),
		"trim_color": Color(0.45, 0.40, 0.35),
		"rug_scale": Vector2(2.5, 2.2),
		"extra_furniture": [],
		"description": "A small studio. Your desk, bed, and kitchen are all in one room.",
	},
	ApartmentTier.ONE_BEDROOM: {
		"floor_color": Color(0.25, 0.20, 0.16),
		"wall_color": Color(0.35, 0.32, 0.28),
		"trim_color": Color(0.50, 0.45, 0.38),
		"rug_scale": Vector2(3.0, 2.5),
		"extra_furniture": ["plant", "lamp", "second_monitor"],
		"description": "A proper one-bedroom. Dedicated desk area with room to breathe.",
	},
	ApartmentTier.HOUSE: {
		"floor_color": Color(0.28, 0.22, 0.17),
		"wall_color": Color(0.38, 0.35, 0.30),
		"trim_color": Color(0.55, 0.48, 0.40),
		"rug_scale": Vector2(3.5, 2.8),
		"extra_furniture": ["plant", "lamp", "second_monitor", "whiteboard", "server_rack", "awards"],
		"description": "A house with a dedicated home office. You've made it.",
	},
}


func _ready() -> void:
	ReputationManager.career_tier_changed.connect(_on_tier_changed)
	_update_apartment(ReputationManager.career_tier)


func _on_tier_changed(_old_tier: int, new_tier: int) -> void:
	_update_apartment(new_tier)


func _update_apartment(career_tier: int) -> void:
	var new_apartment: ApartmentTier = TIER_MAP.get(career_tier, ApartmentTier.STUDIO)
	if new_apartment != current_apartment:
		var old := current_apartment
		current_apartment = new_apartment
		if old != new_apartment:
			apartment_upgraded.emit(new_apartment)


func get_config() -> Dictionary:
	return APARTMENT_CONFIGS.get(current_apartment, APARTMENT_CONFIGS[ApartmentTier.STUDIO])


func get_apartment_name() -> String:
	return APARTMENT_NAMES[current_apartment]
