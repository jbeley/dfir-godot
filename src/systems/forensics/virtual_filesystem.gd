class_name VirtualFilesystem
extends RefCounted
## Per-case in-memory filesystem. Stores evidence files in a tree structure.
## Paths use forward slashes. Root is "/".

var _root: Dictionary = {}  # Nested dict: keys are names, values are either String (file) or Dict (dir)
var _cwd: String = "/"


func _init() -> void:
	_root = {}


## Mount a file at the given absolute path, creating parent directories as needed.
func write_file(path: String, content: String) -> void:
	var parts := _split_path(path)
	if parts.is_empty():
		return
	var filename: String = parts.pop_back()
	var dir: Dictionary = _ensure_dirs(parts)
	dir[filename] = content


## Read a file. Returns empty string if not found.
func read_file(path: String) -> String:
	var node: Variant = _resolve(path)
	if node is String:
		return node as String
	return ""


## Check if a path exists.
func exists(path: String) -> bool:
	return _resolve(path) != null


## Check if path is a directory.
func is_dir(path: String) -> bool:
	return _resolve(path) is Dictionary


## Check if path is a file.
func is_file(path: String) -> bool:
	return _resolve(path) is String


## List entries in a directory. Returns empty array if not a directory.
func list_dir(path: String) -> PackedStringArray:
	var node: Variant = _resolve(path)
	if node is Dictionary:
		var dir_dict: Dictionary = node as Dictionary
		var entries := PackedStringArray()
		for key: String in dir_dict:
			entries.append(key)
		entries.sort()
		return entries
	return PackedStringArray()


## List entries with type indicators (trailing / for dirs).
func list_dir_detailed(path: String) -> PackedStringArray:
	var node: Variant = _resolve(path)
	if node is Dictionary:
		var dir_dict: Dictionary = node as Dictionary
		var entries := PackedStringArray()
		for key: String in dir_dict:
			if dir_dict[key] is Dictionary:
				entries.append(key + "/")
			else:
				entries.append(key)
		entries.sort()
		return entries
	return PackedStringArray()


## Get file size (character count). Returns -1 if not a file.
func file_size(path: String) -> int:
	var node: Variant = _resolve(path)
	if node is String:
		var s: String = node as String
		return s.length()
	return -1


## Get/set the current working directory.
func get_cwd() -> String:
	return _cwd


func set_cwd(path: String) -> bool:
	var resolved := _resolve_abs(path)
	if is_dir(resolved):
		_cwd = resolved
		return true
	return false


## Resolve a relative or absolute path to an absolute path.
func _resolve_abs(path: String) -> String:
	if path.begins_with("/"):
		return _normalize(path)
	return _normalize(_cwd.path_join(path))


## Normalize a path (resolve . and .., remove trailing slash).
func _normalize(path: String) -> String:
	var parts := path.split("/", false)
	var resolved: Array[String] = []
	for p in parts:
		if p == ".":
			continue
		elif p == "..":
			if not resolved.is_empty():
				resolved.pop_back()
		else:
			resolved.append(p)
	if resolved.is_empty():
		return "/"
	return "/" + "/".join(resolved)


## Resolve a path to its node in the tree. Returns null if not found.
func _resolve(path: String) -> Variant:
	var abs_path := _resolve_abs(path)
	if abs_path == "/":
		return _root
	var parts := _split_path(abs_path)
	var current: Variant = _root
	for part: String in parts:
		if current is Dictionary and (current as Dictionary).has(part):
			current = (current as Dictionary)[part]
		else:
			return null
	return current


## Split an absolute path into parts.
func _split_path(path: String) -> Array[String]:
	var parts: Array[String] = []
	for p in path.split("/", false):
		parts.append(p)
	return parts


## Create all directories along the path, return the final directory dict.
func _ensure_dirs(parts: Array[String]) -> Dictionary:
	var current: Dictionary = _root
	for part: String in parts:
		if not current.has(part):
			current[part] = {}
		var next: Variant = current[part]
		if next is Dictionary:
			current = next as Dictionary
		else:
			# Path component exists as a file - overwrite with directory
			var new_dir := {}
			current[part] = new_dir
			current = new_dir
	return current


## Recursively find files matching a glob pattern (simple * only).
func glob(pattern: String, base_path: String = "/") -> PackedStringArray:
	var results := PackedStringArray()
	_glob_recursive(base_path, pattern, results)
	return results


func _glob_recursive(dir_path: String, pattern: String, results: PackedStringArray) -> void:
	var node: Variant = _resolve(dir_path)
	if not node is Dictionary:
		return
	var dir_dict: Dictionary = node as Dictionary
	for key: String in dir_dict:
		var full_path: String = dir_path.rstrip("/") + "/" + key
		if dir_dict[key] is String:
			if _match_glob(key, pattern) or _match_glob(full_path, pattern):
				results.append(full_path)
		elif dir_dict[key] is Dictionary:
			_glob_recursive(full_path, pattern, results)


func _match_glob(text: String, pattern: String) -> bool:
	# Simple glob: * matches any sequence of characters
	if pattern == "*":
		return true
	if "*" not in pattern:
		return text == pattern
	var parts := pattern.split("*")
	var pos := 0
	for i in range(parts.size()):
		var part := parts[i]
		if part == "":
			continue
		var idx := text.find(part, pos)
		if idx == -1:
			return false
		if i == 0 and idx != 0:
			return false  # Pattern doesn't start with *, must match from beginning
		pos = idx + part.length()
	if not pattern.ends_with("*") and pos != text.length():
		return false
	return true


## Get total file count (for stats).
func get_file_count() -> int:
	return _count_files(_root)


func _count_files(node: Dictionary) -> int:
	var count := 0
	for key: String in node:
		if node[key] is String:
			count += 1
		elif node[key] is Dictionary:
			count += _count_files(node[key] as Dictionary)
	return count
