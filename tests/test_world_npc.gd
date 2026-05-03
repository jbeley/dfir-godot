extends Node
## Unit tests for WorldNPC line cycling.
## Run with: godot --headless -s tests/run_tests.gd
##
## Only tests behavior that doesn't depend on autoloads. Anything that
## triggers JournalManager / HeatManager is skipped here and covered by the
## manager-level tests + the integration smoke check.

const WorldNPCScript := preload("res://src/scenes/components/world_npc.gd")

var _pass_count := 0
var _fail_count := 0
var _test_name := ""


func _init() -> void:
	print("=== WorldNPC Tests ===\n")
	test_get_current_line_returns_first_line_when_no_lines()
	test_get_current_line_returns_indexed_line()
	test_lines_cycle_when_index_exceeds_size()
	print("\n=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])
	if _fail_count > 0:
		print("FAILED")
	else:
		print("ALL TESTS PASSED")


func _make() -> Object:
	return WorldNPCScript.new()


func test_get_current_line_returns_first_line_when_no_lines() -> void:
	_test_name = "get_current_line_returns_first_line_when_no_lines"
	var npc: Object = _make()
	npc.first_line = "fallback line"
	assert_eq(npc.get_current_line(), "fallback line")


func test_get_current_line_returns_indexed_line() -> void:
	_test_name = "get_current_line_returns_indexed_line"
	var npc: Object = _make()
	npc.lines = PackedStringArray(["one", "two", "three"])
	assert_eq(npc.get_current_line(), "one")
	npc._line_index = 1
	assert_eq(npc.get_current_line(), "two")
	npc._line_index = 2
	assert_eq(npc.get_current_line(), "three")


func test_lines_cycle_when_index_exceeds_size() -> void:
	_test_name = "lines_cycle_when_index_exceeds_size"
	var npc: Object = _make()
	npc.lines = PackedStringArray(["a", "b"])
	npc._line_index = 4
	assert_eq(npc.get_current_line(), "a")
	npc._line_index = 5
	assert_eq(npc.get_current_line(), "b")


func assert_eq(got: Variant, expected: Variant) -> void:
	if got == expected:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s]: expected '%s', got '%s'" % [_test_name, str(expected), str(got)])
