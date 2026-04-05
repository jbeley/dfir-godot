class_name CmdTail
extends BaseCommand


func get_name() -> String:
	return "tail"


func get_description() -> String:
	return "Display last lines of a file"


func get_usage() -> String:
	return "tail [-n COUNT] [file]"


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	var line_count := 10
	var file_path := ""

	var i := 0
	while i < args.size():
		if args[i] == "-n" and i + 1 < args.size():
			line_count = args[i + 1].to_int()
			if line_count <= 0:
				line_count = 10
			i += 2
		elif args[i].begins_with("-") and args[i].substr(1).is_valid_int():
			line_count = args[i].substr(1).to_int()
			i += 1
		elif not args[i].begins_with("-"):
			file_path = args[i]
			i += 1
		else:
			i += 1

	var text := ""
	if piped_input != "":
		text = piped_input
	elif file_path != "":
		if not vfs or not vfs.exists(file_path):
			return "[color=red]tail: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)
	else:
		return "[color=red]tail: missing file operand[/color]"

	var lines := text.split("\n")
	var start := maxi(0, lines.size() - line_count)
	var result := PackedStringArray()
	for j in range(start, lines.size()):
		result.append(lines[j])
	return "\n".join(result)
