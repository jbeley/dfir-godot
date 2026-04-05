class_name CmdSed
extends BaseCommand


func get_name() -> String:
	return "sed"


func get_description() -> String:
	return "Stream editor for text transformation"


func get_usage() -> String:
	return "sed 's/pattern/replacement/[g]' [file]"


func get_min_tier() -> int:
	return 1  # Junior Analyst


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	if args.is_empty():
		return "[color=red]Usage: sed 's/pattern/replacement/[g]' [file][/color]"

	var expression := args[0]
	var file_path := args[1] if args.size() > 1 else ""

	# Get input
	var text := ""
	if piped_input != "":
		text = piped_input
	elif file_path != "":
		if not vfs or not vfs.exists(file_path):
			return "[color=red]sed: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)
	else:
		return "[color=red]sed: no input[/color]"

	# Parse s/pattern/replacement/flags
	if not expression.begins_with("s"):
		return "[color=red]sed: only substitute (s) command is supported[/color]"

	if expression.length() < 4:
		return "[color=red]sed: invalid expression[/color]"

	var delimiter := expression[1]
	var rest := expression.substr(2)
	var parts := rest.split(delimiter)

	if parts.size() < 2:
		return "[color=red]sed: invalid substitution expression[/color]"

	var pattern := parts[0]
	var replacement := parts[1]
	var global := parts.size() > 2 and "g" in parts[2]

	var lines := text.split("\n")
	var result := PackedStringArray()

	for line in lines:
		if global:
			result.append(line.replace(pattern, replacement))
		else:
			# Only replace first occurrence
			var idx := line.find(pattern)
			if idx >= 0:
				result.append(line.left(idx) + replacement + line.substr(idx + pattern.length()))
			else:
				result.append(line)

	return "\n".join(result)
