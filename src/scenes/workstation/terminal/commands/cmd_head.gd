class_name CmdHead
extends BaseCommand


func get_name() -> String:
	return "head"


func get_description() -> String:
	return "Display first lines of a file"


func get_usage() -> String:
	return "head [-n COUNT] [file]"


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

	var text := read_input(args, piped_input, args.size() - 1 if file_path != "" else -1)
	if text == "" and piped_input == "":
		if file_path == "":
			return "[color=red]head: missing file operand[/color]"
		if not vfs or not vfs.exists(file_path):
			return "[color=red]head: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)

	var lines := text.split("\n")
	var result := PackedStringArray()
	for j in range(mini(line_count, lines.size())):
		result.append(lines[j])
	return "\n".join(result)
