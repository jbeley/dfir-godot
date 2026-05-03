extends SceneTree
## Test runner - executes all test scripts and reports results.
## Usage: godot --headless -s tests/run_tests.gd

func _init() -> void:
	print("╔══════════════════════════════════════╗")
	print("║    DFIR Simulator - Test Suite       ║")
	print("╚══════════════════════════════════════╝")
	print("")

	var test_scripts: Array[String] = [
		"res://tests/test_virtual_filesystem.gd",
		"res://tests/test_command_parser.gd",
		"res://tests/test_commands.gd",
		"res://tests/test_world_manager.gd",
		"res://tests/test_journal_manager.gd",
		"res://tests/test_heat_manager.gd",
		"res://tests/test_world_npc.gd",
	]

	var all_passed := true

	for script_path: String in test_scripts:
		print("─".repeat(50))
		var script: GDScript = load(script_path) as GDScript
		if script == null:
			print("ERROR: Could not load %s" % script_path)
			all_passed = false
			continue

		var instance: Node = script.new()
		# The _init() runs tests and prints results
		instance.free()
		print("")

	print("─".repeat(50))
	if all_passed:
		print("\nALL TEST SUITES COMPLETED")
	else:
		print("\nSOME TEST SUITES FAILED")

	quit()
