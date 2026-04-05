class_name CmdFind
extends BaseCommand


func get_name() -> String:
	return "find"


func get_description() -> String:
	return "Search for files by name pattern"


func get_usage() -> String:
	return "find [path] -name <pattern>"


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	if not vfs:
		return "[color=red]No filesystem mounted.[/color]"

	var search_path := "/"
	var pattern := "*"

	var i := 0
	while i < args.size():
		if args[i] == "-name" and i + 1 < args.size():
			pattern = args[i + 1]
			i += 2
		elif not args[i].begins_with("-"):
			search_path = args[i]
			i += 1
		else:
			i += 1

	var results := vfs.glob(pattern, search_path)
	if results.is_empty():
		return ""
	return "\n".join(results)
