extends Node
## Unit tests for JournalManager.
## Run with: godot --headless -s tests/run_tests.gd
##
## Tests use a fresh script instance per test rather than the autoload, since
## run_tests.gd extends SceneTree and skips autoload registration.

const JournalManagerScript := preload("res://src/autoloads/journal_manager.gd")

var _pass_count := 0
var _fail_count := 0
var _test_name := ""


func _init() -> void:
	print("=== JournalManager Tests ===\n")
	test_visit_increments_counter()
	test_npc_record_overwrites_last_line()
	test_secret_only_records_once()
	test_secret_counter_never_exceeds_known()
	test_rumor_dedupes_by_id()
	test_faction_standing_accumulates()
	test_save_roundtrip_preserves_state()
	test_register_secret_increments_known()
	test_register_secret_dedupes_on_revisit()
	print("\n=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])
	if _fail_count > 0:
		print("FAILED")
	else:
		print("ALL TESTS PASSED")


func _make() -> Object:
	return JournalManagerScript.new()


func test_visit_increments_counter() -> void:
	_test_name = "visit_increments_counter"
	var jm: Object = _make()
	jm.record_location_visited(&"apartment")
	jm.record_location_visited(&"apartment")
	jm.record_location_visited(&"street")
	var visits: Dictionary = jm.get_locations_visited()
	assert_eq(int(visits[&"apartment"]), 2)
	assert_eq(int(visits[&"street"]), 1)


func test_npc_record_overwrites_last_line() -> void:
	_test_name = "npc_record_overwrites_last_line"
	var jm: Object = _make()
	jm.record_npc_met(&"marcie", "Marcie", "RECURRING", "First meet")
	jm.record_npc_met(&"marcie", "Marcie", "RECURRING", "Second meet")
	assert_true(jm.has_met_npc(&"marcie"))
	var npcs: Dictionary = jm.get_npcs_met()
	assert_eq(npcs[&"marcie"]["last_line"], "Second meet")


func test_secret_only_records_once() -> void:
	_test_name = "secret_only_records_once"
	var jm: Object = _make()
	jm.record_secret_found(&"phrack", "Phrack sticker", "v1")
	jm.record_secret_found(&"phrack", "Phrack sticker", "v2")
	var found: Dictionary = jm.get_secrets_found()
	assert_eq(found[&"phrack"]["lore_text"], "v1")


func test_secret_counter_never_exceeds_known() -> void:
	_test_name = "secret_counter_never_exceeds_known"
	var jm: Object = _make()
	jm.register_secret(&"a")
	jm.register_secret(&"b")
	jm.record_secret_found(&"a", "A", "lore")
	assert_true(jm.get_secrets_found_count() <= jm.get_secrets_known_count())


func test_rumor_dedupes_by_id() -> void:
	_test_name = "rumor_dedupes_by_id"
	var jm: Object = _make()
	jm.record_rumor_heard(&"rumor1", "first text")
	jm.record_rumor_heard(&"rumor1", "second text")
	var rumors: Dictionary = jm.get_rumors_heard()
	assert_eq(str(rumors[&"rumor1"]), "first text")


func test_faction_standing_accumulates() -> void:
	_test_name = "faction_standing_accumulates"
	var jm: Object = _make()
	jm.record_faction_interaction(&"darklock", 5)
	jm.record_faction_interaction(&"darklock", -2)
	assert_eq(jm.get_faction_standing(&"darklock"), 3)


func test_save_roundtrip_preserves_state() -> void:
	_test_name = "save_roundtrip_preserves_state"
	var jm: Object = _make()
	jm.record_location_visited(&"apartment")
	jm.record_location_visited(&"apartment")
	jm.record_npc_met(&"marcie", "Marcie", "RECURRING", "hi")
	jm.record_secret_found(&"phrack", "Phrack", "lore")
	jm.record_rumor_heard(&"rumor1", "buzz")
	jm.record_faction_interaction(&"fbi", 1)
	var data: Dictionary = jm.to_save_dict()
	var jm2: Object = _make()
	jm2.from_save_dict(data)
	assert_eq(int(jm2.get_locations_visited()[&"apartment"]), 2)
	assert_true(jm2.has_met_npc(&"marcie"))
	assert_true(jm2.has_found_secret(&"phrack"))
	assert_eq(jm2.get_faction_standing(&"fbi"), 1)
	assert_eq(str(jm2.get_rumors_heard()[&"rumor1"]), "buzz")


func test_register_secret_increments_known() -> void:
	_test_name = "register_secret_increments_known"
	var jm: Object = _make()
	assert_eq(jm.get_secrets_known_count(), 0)
	jm.register_secret(&"a")
	jm.register_secret(&"b")
	assert_eq(jm.get_secrets_known_count(), 2)


func test_register_secret_dedupes_on_revisit() -> void:
	_test_name = "register_secret_dedupes_on_revisit"
	var jm: Object = _make()
	jm.register_secret(&"a")
	jm.register_secret(&"a")
	jm.register_secret(&"a")
	assert_eq(jm.get_secrets_known_count(), 1)


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
