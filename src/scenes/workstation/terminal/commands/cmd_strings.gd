class_name CmdStrings
extends BaseCommand


func get_name() -> String:
	return "strings"


func get_description() -> String:
	return "Extract printable strings from binary data"


func get_usage() -> String:
	return "strings [-n MIN_LEN] <file>"


func get_min_tier() -> int:
	return 1  # Junior Analyst


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	var min_len := 4
	var file_path := ""

	var i := 0
	while i < args.size():
		if args[i] == "-n" and i + 1 < args.size():
			min_len = args[i + 1].to_int()
			i += 2
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
			return "[color=red]strings: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)
	else:
		return "[color=red]strings: missing file operand[/color]"

	# In our virtual filesystem, everything is already text, but we simulate
	# extracting "interesting" strings by filtering for lines with printable content
	var lines := text.split("\n")
	var result := PackedStringArray()
	for line in lines:
		var stripped := line.strip_edges()
		if stripped.length() >= min_len:
			result.append(stripped)
	return "\n".join(result)
