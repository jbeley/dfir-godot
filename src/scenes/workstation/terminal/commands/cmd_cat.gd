class_name CmdCat
extends BaseCommand


func get_name() -> String:
	return "cat"


func get_description() -> String:
	return "Display file contents"


func get_usage() -> String:
	return "cat [-n] <file> [file2 ...]"


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	if piped_input != "" and args.is_empty():
		return piped_input

	if not vfs:
		return "[color=red]No filesystem mounted. Open a case first.[/color]"

	var show_line_numbers := false
	var files: PackedStringArray = []

	for arg in args:
		if arg == "-n":
			show_line_numbers = true
		elif not arg.begins_with("-"):
			files.append(arg)

	if files.is_empty():
		if piped_input != "":
			if show_line_numbers:
				return _add_line_numbers(piped_input)
			return piped_input
		return "[color=red]cat: missing file operand[/color]"

	var output := ""
	for file_path in files:
		if not vfs.exists(file_path):
			output += "[color=red]cat: %s: No such file or directory[/color]\n" % file_path
			continue
		if vfs.is_dir(file_path):
			output += "[color=red]cat: %s: Is a directory[/color]\n" % file_path
			continue
		var content := vfs.read_file(file_path)
		if show_line_numbers:
			content = _add_line_numbers(content)
		output += content
		if not output.ends_with("\n"):
			output += "\n"

	return output.strip_edges()


func _add_line_numbers(text: String) -> String:
	var lines := text.split("\n")
	var output := ""
	for i in range(lines.size()):
		output += "%6d  %s\n" % [i + 1, lines[i]]
	return output
