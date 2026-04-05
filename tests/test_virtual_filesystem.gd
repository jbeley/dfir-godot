extends Node
## Unit tests for VirtualFilesystem.
## Run with: godot --headless -s tests/run_tests.gd

var _pass_count := 0
var _fail_count := 0
var _test_name := ""


func _init() -> void:
	print("=== VirtualFilesystem Tests ===\n")

	test_write_and_read()
	test_exists()
	test_is_dir_and_is_file()
	test_list_dir()
	test_list_dir_detailed()
	test_nested_directories()
	test_file_size()
	test_cwd_and_navigation()
	test_normalize_path()
	test_glob()
	test_overwrite_file()
	test_nonexistent_file()
	test_file_count()

	print("\n=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])
	if _fail_count > 0:
		print("FAILED")
	else:
		print("ALL TESTS PASSED")


func test_write_and_read() -> void:
	_test_name = "write_and_read"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/evidence/logs/auth.log", "Jan 14 root login")
	assert_eq(vfs.read_file("/evidence/logs/auth.log"), "Jan 14 root login")


func test_exists() -> void:
	_test_name = "exists"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/test.txt", "hello")
	assert_true(vfs.exists("/test.txt"))
	assert_true(vfs.exists("/"))
	assert_false(vfs.exists("/nonexistent"))


func test_is_dir_and_is_file() -> void:
	_test_name = "is_dir_and_is_file"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/dir/file.txt", "content")
	assert_true(vfs.is_file("/dir/file.txt"))
	assert_false(vfs.is_dir("/dir/file.txt"))
	assert_true(vfs.is_dir("/dir"))
	assert_false(vfs.is_file("/dir"))
	assert_true(vfs.is_dir("/"))


func test_list_dir() -> void:
	_test_name = "list_dir"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/a.txt", "a")
	vfs.write_file("/b.txt", "b")
	vfs.write_file("/sub/c.txt", "c")
	var entries := vfs.list_dir("/")
	assert_eq(entries.size(), 3)  # a.txt, b.txt, sub
	assert_true("a.txt" in entries)
	assert_true("b.txt" in entries)
	assert_true("sub" in entries)


func test_list_dir_detailed() -> void:
	_test_name = "list_dir_detailed"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/file.txt", "data")
	vfs.write_file("/subdir/nested.txt", "nested")
	var entries := vfs.list_dir_detailed("/")
	assert_true("file.txt" in entries)
	assert_true("subdir/" in entries)


func test_nested_directories() -> void:
	_test_name = "nested_directories"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/a/b/c/d/file.txt", "deep")
	assert_eq(vfs.read_file("/a/b/c/d/file.txt"), "deep")
	assert_true(vfs.is_dir("/a"))
	assert_true(vfs.is_dir("/a/b"))
	assert_true(vfs.is_dir("/a/b/c"))
	assert_true(vfs.is_dir("/a/b/c/d"))


func test_file_size() -> void:
	_test_name = "file_size"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/test.txt", "12345")
	assert_eq(vfs.file_size("/test.txt"), 5)
	assert_eq(vfs.file_size("/nonexistent"), -1)


func test_cwd_and_navigation() -> void:
	_test_name = "cwd_and_navigation"
	var vfs := VirtualFilesystem.new()
	assert_eq(vfs.get_cwd(), "/")
	vfs.write_file("/home/user/file.txt", "data")
	assert_true(vfs.set_cwd("/home/user"))
	assert_eq(vfs.get_cwd(), "/home/user")
	assert_false(vfs.set_cwd("/nonexistent"))
	assert_eq(vfs.get_cwd(), "/home/user")  # Unchanged


func test_normalize_path() -> void:
	_test_name = "normalize_path"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/a/b/file.txt", "data")
	# Test .. resolution
	assert_eq(vfs._normalize("/a/b/../b/file.txt"), "/a/b/file.txt")
	assert_eq(vfs._normalize("/a/b/../../a/b"), "/a/b")
	assert_eq(vfs._normalize("/a/./b/./file.txt"), "/a/b/file.txt")
	assert_eq(vfs._normalize("/../.."), "/")


func test_glob() -> void:
	_test_name = "glob"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/logs/auth.log", "auth data")
	vfs.write_file("/logs/syslog", "sys data")
	vfs.write_file("/logs/access.log", "access data")
	vfs.write_file("/other/readme.txt", "readme")
	var results := vfs.glob("*.log")
	assert_eq(results.size(), 2)


func test_overwrite_file() -> void:
	_test_name = "overwrite_file"
	var vfs := VirtualFilesystem.new()
	vfs.write_file("/test.txt", "original")
	vfs.write_file("/test.txt", "updated")
	assert_eq(vfs.read_file("/test.txt"), "updated")


func test_nonexistent_file() -> void:
	_test_name = "nonexistent_file"
	var vfs := VirtualFilesystem.new()
	assert_eq(vfs.read_file("/nope"), "")
	assert_false(vfs.exists("/nope"))


func test_file_count() -> void:
	_test_name = "file_count"
	var vfs := VirtualFilesystem.new()
	assert_eq(vfs.get_file_count(), 0)
	vfs.write_file("/a.txt", "a")
	vfs.write_file("/b/c.txt", "c")
	vfs.write_file("/b/d.txt", "d")
	assert_eq(vfs.get_file_count(), 3)


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
