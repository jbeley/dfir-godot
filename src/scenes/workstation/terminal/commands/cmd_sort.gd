class_name CmdSort
extends BaseCommand


func get_name() -> String:
	return "sort"


func get_description() -> String:
	return "Sort lines of text"


func get_usage() -> String:
	return "sort [-r] [-n] [-u] [file]"


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	var reverse := false
	var numeric := false
	var unique := false
	var file_path := ""

	for arg in args:
		match arg:
			"-r": reverse = true
			"-n": numeric = true
			"-u": unique = true
			"-rn", "-nr": reverse = true; numeric = true
			"-ru", "-ur": reverse = true; unique = true
			"-nu", "-un": numeric = true; unique = true
			_:
				if not arg.begins_with("-"):
					file_path = arg

	var text := ""
	if piped_input != "":
		text = piped_input
	elif file_path != "":
		if not vfs or not vfs.exists(file_path):
			return "[color=red]sort: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)
	else:
		return "[color=red]sort: no input[/color]"

	var lines := Array(text.split("\n"))

	# Remove empty trailing lines
	while not lines.is_empty() and lines[-1].strip_edges() == "":
		lines.pop_back()

	if numeric:
		lines.sort_custom(func(a: String, b: String) -> bool:
			return a.to_float() < b.to_float()
		)
	else:
		lines.sort()

	if reverse:
		lines.reverse()

	if unique:
		var seen := {}
		var filtered: Array = []
		for line: String in lines:
			if not seen.has(line):
				seen[line] = true
				filtered.append(line)
		lines = filtered

	return "\n".join(PackedStringArray(lines))
