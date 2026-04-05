class_name CmdUniq
extends BaseCommand


func get_name() -> String:
	return "uniq"


func get_description() -> String:
	return "Filter adjacent duplicate lines"


func get_usage() -> String:
	return "uniq [-c] [-d] [file]"


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	var count_mode := false
	var duplicates_only := false
	var file_path := ""

	for arg in args:
		match arg:
			"-c": count_mode = true
			"-d": duplicates_only = true
			_:
				if not arg.begins_with("-"):
					file_path = arg

	var text := ""
	if piped_input != "":
		text = piped_input
	elif file_path != "":
		if not vfs or not vfs.exists(file_path):
			return "[color=red]uniq: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)
	else:
		return "[color=red]uniq: no input[/color]"

	var lines := text.split("\n")
	var result := PackedStringArray()
	var prev := ""
	var prev_count := 0

	for i in range(lines.size()):
		if i == 0:
			prev = lines[i]
			prev_count = 1
			continue

		if lines[i] == prev:
			prev_count += 1
		else:
			_emit_line(result, prev, prev_count, count_mode, duplicates_only)
			prev = lines[i]
			prev_count = 1

	# Don't forget the last group
	if prev_count > 0:
		_emit_line(result, prev, prev_count, count_mode, duplicates_only)

	return "\n".join(result)


func _emit_line(result: PackedStringArray, line: String, count: int,
		count_mode: bool, duplicates_only: bool) -> void:
	if duplicates_only and count < 2:
		return
	if count_mode:
		result.append("%7d %s" % [count, line])
	else:
		result.append(line)
