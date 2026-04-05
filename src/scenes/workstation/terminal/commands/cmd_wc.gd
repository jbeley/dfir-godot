class_name CmdWc
extends BaseCommand


func get_name() -> String:
	return "wc"


func get_description() -> String:
	return "Count lines, words, and characters"


func get_usage() -> String:
	return "wc [-l] [-w] [-c] [file]"


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	var lines_only := false
	var words_only := false
	var chars_only := false
	var file_path := ""

	for arg in args:
		match arg:
			"-l": lines_only = true
			"-w": words_only = true
			"-c": chars_only = true
			_:
				if not arg.begins_with("-"):
					file_path = arg

	var text := ""
	if piped_input != "":
		text = piped_input
	elif file_path != "":
		if not vfs or not vfs.exists(file_path):
			return "[color=red]wc: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)
	else:
		return "[color=red]wc: no input[/color]"

	var line_count := text.count("\n")
	if text != "" and not text.ends_with("\n"):
		line_count += 1
	var word_count := text.split(" ", false).size()
	var char_count := text.length()
	var label := file_path if file_path != "" else ""

	if lines_only:
		return "%d %s" % [line_count, label]
	if words_only:
		return "%d %s" % [word_count, label]
	if chars_only:
		return "%d %s" % [char_count, label]

	return "%d %d %d %s" % [line_count, word_count, char_count, label]
