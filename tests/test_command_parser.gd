extends Node
## Unit tests for CommandParser.

var _pass_count := 0
var _fail_count := 0
var _test_name := ""


func _init() -> void:
	print("=== CommandParser Tests ===\n")

	test_simple_command()
	test_command_with_args()
	test_command_with_flags()
	test_quoted_strings()
	test_pipe()
	test_multi_pipe()
	test_redirect()
	test_pipe_and_redirect()
	test_empty_input()
	test_flag_helpers()

	print("\n=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])
	if _fail_count > 0:
		print("FAILED")
	else:
		print("ALL TESTS PASSED")


func test_simple_command() -> void:
	_test_name = "simple_command"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("ls")
	assert_eq(pipeline.commands.size(), 1)
	assert_eq(pipeline.commands[0].name, "ls")
	assert_eq(pipeline.commands[0].args.size(), 0)


func test_command_with_args() -> void:
	_test_name = "command_with_args"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("grep error /var/log/syslog")
	assert_eq(pipeline.commands[0].name, "grep")
	assert_eq(pipeline.commands[0].args.size(), 2)
	assert_eq(pipeline.commands[0].args[0], "error")
	assert_eq(pipeline.commands[0].args[1], "/var/log/syslog")


func test_command_with_flags() -> void:
	_test_name = "command_with_flags"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("grep -i -n pattern file.txt")
	var cmd: CommandParser.ParsedCommand = pipeline.commands[0]
	assert_true(cmd.has_flag("-i"))
	assert_true(cmd.has_flag("-n"))
	assert_false(cmd.has_flag("-v"))


func test_quoted_strings() -> void:
	_test_name = "quoted_strings"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("grep 'hello world' file.txt")
	assert_eq(pipeline.commands[0].args[0], "hello world")
	assert_eq(pipeline.commands[0].args[1], "file.txt")


func test_pipe() -> void:
	_test_name = "pipe"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("cat file.txt | grep error")
	assert_true(pipeline.is_piped())
	assert_eq(pipeline.commands.size(), 2)
	assert_eq(pipeline.commands[0].name, "cat")
	assert_eq(pipeline.commands[1].name, "grep")


func test_multi_pipe() -> void:
	_test_name = "multi_pipe"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("cat log | grep error | sort | uniq -c")
	assert_eq(pipeline.commands.size(), 4)
	assert_eq(pipeline.commands[0].name, "cat")
	assert_eq(pipeline.commands[1].name, "grep")
	assert_eq(pipeline.commands[2].name, "sort")
	assert_eq(pipeline.commands[3].name, "uniq")
	assert_eq(pipeline.commands[3].args[0], "-c")


func test_redirect() -> void:
	_test_name = "redirect"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("grep error log.txt > results.txt")
	assert_eq(pipeline.commands.size(), 1)
	assert_eq(pipeline.redirect_file, "results.txt")


func test_pipe_and_redirect() -> void:
	_test_name = "pipe_and_redirect"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("cat log | grep error > out.txt")
	assert_eq(pipeline.commands.size(), 2)
	assert_eq(pipeline.redirect_file, "out.txt")


func test_empty_input() -> void:
	_test_name = "empty_input"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("")
	assert_eq(pipeline.commands.size(), 0)


func test_flag_helpers() -> void:
	_test_name = "flag_helpers"
	var pipeline: CommandParser.Pipeline = CommandParser.parse("head -n 20 file.txt")
	var cmd: CommandParser.ParsedCommand = pipeline.commands[0]
	assert_eq(cmd.get_flag_value("-n", "10"), "20")
	assert_eq(cmd.get_flag_value("-x", "default"), "default")
	assert_eq(cmd.get_arg(0, ""), "-n")
	assert_eq(cmd.get_arg(2, ""), "file.txt")
	assert_eq(cmd.get_arg(99, "fallback"), "fallback")


# --- Test helpers ---

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
