extends Node
## Unit tests for WorldManager + LocationsRegistry.
## Run with: godot --headless -s tests/run_tests.gd
##
## Tests instantiate the script directly rather than referencing the autoload,
## because run_tests.gd extends SceneTree and skips autoload registration.

const WorldManagerScript := preload("res://src/autoloads/world_manager.gd")
const LocationsRegistry := preload("res://src/systems/world/locations_registry.gd")

var _pass_count := 0
var _fail_count := 0
var _test_name := ""


func _init() -> void:
	print("=== WorldManager Tests ===\n")
	test_registry_has_core_locations()
	test_registry_has_acme_locations()
	test_acme_lobby_records_darklock_faction()
	test_get_location_unknown_returns_null()
	test_consume_spawn_id_default()
	test_save_roundtrip_preserves_state()
	test_discovery_dedupes()
	test_to_save_dict_serializes_to_strings()
	print("\n=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])
	if _fail_count > 0:
		print("FAILED")
	else:
		print("ALL TESTS PASSED")


func _make() -> Object:
	return WorldManagerScript.new()


func test_registry_has_core_locations() -> void:
	_test_name = "registry_has_core_locations"
	var all := LocationsRegistry.all()
	assert_true(all.has("apartment"))
	assert_true(all.has("street_downtown"))
	assert_true(all.has("site_shell"))


func test_registry_has_acme_locations() -> void:
	_test_name = "registry_has_acme_locations"
	var all := LocationsRegistry.all()
	assert_true(all.has("site_acme_lobby"))
	assert_true(all.has("site_acme_cubes"))
	assert_true(all.has("site_acme_server"))
	assert_true(all.has("site_acme_alley"))


func test_acme_lobby_records_darklock_faction() -> void:
	_test_name = "acme_lobby_records_darklock_faction"
	var lobby: Resource = LocationsRegistry.get_location(&"site_acme_lobby")
	assert_true(lobby != null)
	var factions: Array[StringName] = lobby.faction_presence
	assert_true(factions.has(&"darklock"))


func test_get_location_unknown_returns_null() -> void:
	_test_name = "get_location_unknown_returns_null"
	assert_true(LocationsRegistry.get_location(&"nonexistent_place") == null)


func test_consume_spawn_id_default() -> void:
	_test_name = "consume_spawn_id_default"
	var wm: Object = _make()
	assert_eq(wm.consume_spawn_id(), &"default")


func test_save_roundtrip_preserves_state() -> void:
	_test_name = "save_roundtrip_preserves_state"
	var wm: Object = _make()
	wm.current_location_id = &"street_downtown"
	var discovered: Array[StringName] = [&"apartment", &"street_downtown"]
	wm.discovered_locations = discovered
	var data: Dictionary = wm.to_save_dict()
	var wm2: Object = _make()
	wm2.from_save_dict(data)
	assert_eq(wm2.current_location_id, &"street_downtown")
	assert_true(wm2.is_discovered(&"apartment"))
	assert_true(wm2.is_discovered(&"street_downtown"))
	assert_false(wm2.is_discovered(&"site_shell"))


func test_discovery_dedupes() -> void:
	_test_name = "discovery_dedupes"
	var wm: Object = _make()
	wm._record_discovery(&"apartment")
	wm._record_discovery(&"apartment")
	wm._record_discovery(&"apartment")
	assert_eq(wm.get_discovered_count(), 1)


func test_to_save_dict_serializes_to_strings() -> void:
	_test_name = "to_save_dict_serializes_to_strings"
	var wm: Object = _make()
	var discovered: Array[StringName] = [&"apartment"]
	wm.discovered_locations = discovered
	var data: Dictionary = wm.to_save_dict()
	var ids: Variant = data["discovered_locations"]
	assert_true(ids is Array)
	assert_true(ids[0] is String)


func assert_eq(got: Variant, expected: Variant) -> void:
	if got == expected:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s]: expected '%s', got '%s'" % [_test_name, str(expected), str(got)])


func assert_true(condition: bool) -> void:
	if condition:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s]: expected true" % _test_name)


func assert_false(condition: bool) -> void:
	if not condition:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s]: expected false" % _test_name)
