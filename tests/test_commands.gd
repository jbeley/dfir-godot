extends Node
## Unit tests for individual terminal commands.

var _pass_count := 0
var _fail_count := 0
var _test_name := ""
var vfs: VirtualFilesystem


func _init() -> void:
	print("=== Terminal Command Tests ===\n")

	# Set up shared VFS with test data
	vfs = VirtualFilesystem.new()
	vfs.write_file("/logs/auth.log", "Jan 14 21:45:33 server sshd: Failed password for root from 192.168.1.50\nJan 14 21:45:35 server sshd: Failed password for root from 192.168.1.50\nJan 14 21:46:02 server sshd: Accepted password for admin from 10.0.0.1\nJan 14 22:00:00 server cron: running backup")
	vfs.write_file("/logs/access.log", "192.168.1.50 - - [14/Jan] \"GET /admin HTTP/1.1\" 403\n10.0.0.1 - - [14/Jan] \"GET /index.html HTTP/1.1\" 200\n192.168.1.50 - - [14/Jan] \"POST /api/upload HTTP/1.1\" 200")
	vfs.write_file("/evidence/note.txt", "ENCRYPTED BY DARKLOCK\nSend 2 BTC to bc1qxyz\nContact: ransom@evil.com")

	test_cat()
	test_cat_line_numbers()
	test_grep_basic()
	test_grep_case_insensitive()
	test_grep_invert()
	test_grep_count()
	test_head()
	test_tail()
	test_wc()
	test_sort()
	test_uniq()
	test_hash()
	test_find()
	test_cd_and_pwd()
	test_pipe_grep_to_wc()
	test_pipe_cat_grep_sort()

	print("\n=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])
	if _fail_count > 0:
		print("FAILED")
	else:
		print("ALL TESTS PASSED")


func _make_cmd(cmd: BaseCommand) -> BaseCommand:
	cmd.vfs = vfs
	return cmd


func test_cat() -> void:
	_test_name = "cat"
	var cmd := _make_cmd(CmdCat.new())
	var output := cmd.execute(PackedStringArray(["/evidence/note.txt"]))
	assert_contains(output, "DARKLOCK")
	assert_contains(output, "bc1qxyz")


func test_cat_line_numbers() -> void:
	_test_name = "cat_line_numbers"
	var cmd := _make_cmd(CmdCat.new())
	var output := cmd.execute(PackedStringArray(["-n", "/evidence/note.txt"]))
	assert_contains(output, "1")
	assert_contains(output, "DARKLOCK")


func test_grep_basic() -> void:
	_test_name = "grep_basic"
	var cmd := _make_cmd(CmdGrep.new())
	var output := cmd.execute(PackedStringArray(["Failed", "/logs/auth.log"]))
	# Output contains BBCode highlighting, so check for the surrounding text
	assert_contains(output, "password for root")
	# Should have 2 matching lines
	var lines := output.split("\n")
	var non_empty := 0
	for line: String in lines:
		if line.strip_edges() != "":
			non_empty += 1
	assert_eq(non_empty, 2)


func test_grep_case_insensitive() -> void:
	_test_name = "grep_case_insensitive"
	var cmd := _make_cmd(CmdGrep.new())
	var output := cmd.execute(PackedStringArray(["-i", "failed", "/logs/auth.log"]))
	assert_contains(output, "password for root")


func test_grep_invert() -> void:
	_test_name = "grep_invert"
	var cmd := _make_cmd(CmdGrep.new())
	var output := cmd.execute(PackedStringArray(["-v", "Failed", "/logs/auth.log"]))
	assert_not_contains(output, "Failed")
	assert_contains(output, "Accepted")


func test_grep_count() -> void:
	_test_name = "grep_count"
	var cmd := _make_cmd(CmdGrep.new())
	var output := cmd.execute(PackedStringArray(["-c", "Failed", "/logs/auth.log"]))
	assert_eq(output.strip_edges(), "2")


func test_head() -> void:
	_test_name = "head"
	var cmd := _make_cmd(CmdHead.new())
	var output := cmd.execute(PackedStringArray(["-n", "2", "/logs/auth.log"]))
	var lines := output.split("\n")
	assert_eq(lines.size(), 2)


func test_tail() -> void:
	_test_name = "tail"
	var cmd := _make_cmd(CmdTail.new())
	var output := cmd.execute(PackedStringArray(["-n", "1", "/logs/auth.log"]))
	assert_contains(output, "cron")


func test_wc() -> void:
	_test_name = "wc"
	var cmd := _make_cmd(CmdWc.new())
	var output := cmd.execute(PackedStringArray(["-l", "/logs/auth.log"]))
	assert_contains(output, "4")


func test_sort() -> void:
	_test_name = "sort"
	var cmd := _make_cmd(CmdSort.new())
	var input := "banana\napple\ncherry"
	var output := cmd.execute(PackedStringArray([]), input)
	var lines := output.split("\n")
	assert_eq(lines[0], "apple")
	assert_eq(lines[1], "banana")
	assert_eq(lines[2], "cherry")


func test_uniq() -> void:
	_test_name = "uniq"
	var cmd := _make_cmd(CmdUniq.new())
	var input := "aaa\naaa\nbbb\nbbb\nbbb\nccc"
	var output := cmd.execute(PackedStringArray(["-c"]), input)
	assert_contains(output, "2 aaa")
	assert_contains(output, "3 bbb")
	assert_contains(output, "1 ccc")


func test_hash() -> void:
	_test_name = "hash"
	var cmd := _make_cmd(CmdHash.new())
	var output := cmd.execute(PackedStringArray(["-md5", "/evidence/note.txt"]))
	# Should return a 32-char hex hash
	var hash_part := output.split("  ")[0]
	assert_eq(hash_part.length(), 32)


func test_find() -> void:
	_test_name = "find"
	var cmd := _make_cmd(CmdFind.new())
	var output := cmd.execute(PackedStringArray(["/", "-name", "*.log"]))
	assert_contains(output, "auth.log")
	assert_contains(output, "access.log")


func test_cd_and_pwd() -> void:
	_test_name = "cd_and_pwd"
	var cmd_cd := _make_cmd(CmdCd.new())
	var cmd_pwd := _make_cmd(CmdPwd.new())

	assert_eq(cmd_pwd.execute(PackedStringArray([])), "/")
	cmd_cd.execute(PackedStringArray(["/logs"]))
	assert_eq(cmd_pwd.execute(PackedStringArray([])), "/logs")


func test_pipe_grep_to_wc() -> void:
	_test_name = "pipe_grep_to_wc"
	var grep := _make_cmd(CmdGrep.new())
	var wc := _make_cmd(CmdWc.new())

	var grep_output := grep.execute(PackedStringArray(["192.168.1.50", "/logs/access.log"]))
	var wc_output := wc.execute(PackedStringArray(["-l"]), grep_output)
	assert_contains(wc_output, "2")


func test_pipe_cat_grep_sort() -> void:
	_test_name = "pipe_cat_grep_sort"
	var cat := _make_cmd(CmdCat.new())
	var grep := _make_cmd(CmdGrep.new())
	var sort := _make_cmd(CmdSort.new())

	var cat_out := cat.execute(PackedStringArray(["/logs/auth.log"]))
	var grep_out := grep.execute(PackedStringArray(["password"]), cat_out)
	var sort_out := sort.execute(PackedStringArray([]), grep_out)
	assert_contains(sort_out, "password")


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


func assert_contains(text: String, substring: String) -> void:
	if substring in text:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s]: '%s' not found in output" % [_test_name, substring])


func assert_not_contains(text: String, substring: String) -> void:
	if substring not in text:
		_pass_count += 1
	else:
		_fail_count += 1
		print("  FAIL [%s]: '%s' should not be in output" % [_test_name, substring])
