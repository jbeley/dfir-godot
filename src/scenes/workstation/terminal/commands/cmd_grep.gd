class_name CmdGrep
extends BaseCommand


func get_name() -> String:
	return "grep"


func get_description() -> String:
	return "Search for patterns in text"


func get_usage() -> String:
	return "grep [-i] [-v] [-c] [-n] <pattern> [file]"


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	if args.is_empty():
		return "[color=red]Usage: grep [-i] [-v] [-c] [-n] <pattern> [file][/color]"

	var ignore_case := false
	var invert := false
	var count_only := false
	var show_line_nums := false
	var pattern := ""
	var file_path := ""

	for arg in args:
		match arg:
			"-i":
				ignore_case = true
			"-v":
				invert = true
			"-c":
				count_only = true
			"-n":
				show_line_nums = true
			"-iv", "-vi":
				ignore_case = true
				invert = true
			"-in", "-ni":
				ignore_case = true
				show_line_nums = true
			_:
				if not arg.begins_with("-"):
					if pattern == "":
						pattern = arg
					else:
						file_path = arg

	if pattern == "":
		return "[color=red]grep: missing pattern[/color]"

	# Get input text
	var text := ""
	if piped_input != "":
		text = piped_input
	elif file_path != "":
		if not vfs:
			return "[color=red]No filesystem mounted.[/color]"
		if not vfs.exists(file_path):
			return "[color=red]grep: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)
	else:
		return "[color=red]grep: no input (pipe data or specify a file)[/color]"

	var lines := text.split("\n")
	var matches := PackedStringArray()
	var match_count := 0

	var search_pattern := pattern
	if ignore_case:
		search_pattern = pattern.to_lower()

	for i in range(lines.size()):
		var line := lines[i]
		var compare_line := line.to_lower() if ignore_case else line
		var found := compare_line.contains(search_pattern)

		if (found and not invert) or (not found and invert):
			match_count += 1
			if not count_only:
				var prefix := "%d:" % (i + 1) if show_line_nums else ""
				# Highlight matches
				var display_line := line
				if found and not invert:
					display_line = _highlight_match(line, pattern, ignore_case)
				matches.append(prefix + display_line)

	if count_only:
		return str(match_count)

	if matches.is_empty():
		return ""

	return "\n".join(matches)


func _highlight_match(line: String, pattern: String, ignore_case: bool) -> String:
	var search_line := line.to_lower() if ignore_case else line
	var search_pat := pattern.to_lower() if ignore_case else pattern
	var result := ""
	var pos := 0

	while pos < line.length():
		var idx := search_line.find(search_pat, pos)
		if idx == -1:
			result += line.substr(pos)
			break
		result += line.substr(pos, idx - pos)
		result += "[color=red][b]%s[/b][/color]" % line.substr(idx, pattern.length())
		pos = idx + pattern.length()

	return result
