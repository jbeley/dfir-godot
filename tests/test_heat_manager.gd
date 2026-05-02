extends Node
## Unit tests for HeatManager.
## Run with: godot --headless -s tests/run_tests.gd
##
## Tests use a fresh script instance per test rather than the autoload, since
## run_tests.gd extends SceneTree and skips autoload registration. We only test
## state methods, not the TimeManager-driven decay (which requires the SceneTree).

const HeatManagerScript := preload("res://src/autoloads/heat_manager.gd")

var _pass_count := 0
var _fail_count := 0
var _test_name := ""


func _init() -> void:
	print("=== HeatManager Tests ===\n")
	test_add_heat_clamps_to_max()
	test_add_heat_clamps_to_zero()
	test_thresholds_classify_correctly()
	test_threshold_signal_fires_once()
	test_save_roundtrip_preserves_state()
	test_unknown_faction_reads_zero()
	print("\n=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])
	if _fail_count > 0:
		print("FAILED")
	else:
		print("ALL TESTS PASSED")


func _make() -> Object:
	return HeatManagerScript.new()


func test_add_heat_clamps_to_max() -> void:
	_test_name = "add_heat_clamps_to_max"
	var hm: Object = _make()
	hm.add_heat(&"darklock", 500.0)
	assert_eq(hm.get_heat(&"darklock"), HeatManagerScript.MAX_HEAT)


func test_add_heat_clamps_to_zero() -> void:
	_test_name = "add_heat_clamps_to_zero"
	var hm: Object = _make()
	hm.add_heat(&"darklock", -50.0)
	assert_eq(hm.get_heat(&"darklock"), 0.0)


func test_thresholds_classify_correctly() -> void:
	_test_name = "thresholds_classify_correctly"
	var hm: Object = _make()
	hm.add_heat(&"phantom_bear", 10.0)
	assert_false(hm.is_noticed(&"phantom_bear"))
	hm.add_heat(&"phantom_bear", 20.0)
	assert_true(hm.is_noticed(&"phantom_bear"))
	assert_false(hm.is_hostile(&"phantom_bear"))
	hm.add_heat(&"phantom_bear", 35.0)
	assert_true(hm.is_hostile(&"phantom_bear"))


func test_threshold_signal_fires_once() -> void:
	_test_name = "threshold_signal_fires_once"
	var hm: Object = _make()
	var fires: Array = []
	var f := func(_faction: StringName, threshold: float) -> void: fires.append(threshold)
	hm.heat_threshold_crossed.connect(f)
	hm.add_heat(&"fbi", 30.0)
	hm.add_heat(&"fbi", 1.0)
	hm.add_heat(&"fbi", 1.0)
	hm.heat_threshold_crossed.disconnect(f)
	var noticed_fires: int = 0
	for v: float in fires:
		if v == HeatManagerScript.THRESHOLD_NOTICED:
			noticed_fires += 1
	assert_eq(noticed_fires, 1)


func test_save_roundtrip_preserves_state() -> void:
	_test_name = "save_roundtrip_preserves_state"
	var hm: Object = _make()
	hm.add_heat(&"darklock", 12.0)
	hm.add_heat(&"phantom_bear", 70.0)
	var data: Dictionary = hm.to_save_dict()
	var hm2: Object = _make()
	hm2.from_save_dict(data)
	assert_eq(hm2.get_heat(&"darklock"), 12.0)
	assert_eq(hm2.get_heat(&"phantom_bear"), 70.0)


func test_unknown_faction_reads_zero() -> void:
	_test_name = "unknown_faction_reads_zero"
	var hm: Object = _make()
	assert_eq(hm.get_heat(&"never_heard_of_them"), 0.0)


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
