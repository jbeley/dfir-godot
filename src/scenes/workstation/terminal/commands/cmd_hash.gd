class_name CmdHash
extends BaseCommand


func get_name() -> String:
	return "hash"


func get_description() -> String:
	return "Compute MD5/SHA256 hash of a file"


func get_usage() -> String:
	return "hash [-md5|-sha256] <file>"


func get_min_tier() -> int:
	return 0  # Intern


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	var algo := "sha256"
	var file_path := ""

	for arg in args:
		match arg:
			"-md5": algo = "md5"
			"-sha256": algo = "sha256"
			_:
				if not arg.begins_with("-"):
					file_path = arg

	var text := ""
	if piped_input != "":
		text = piped_input
	elif file_path != "":
		if not vfs or not vfs.exists(file_path):
			return "[color=red]hash: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)
	else:
		return "[color=red]hash: missing file operand[/color]"

	var hash_val := ""
	match algo:
		"md5":
			hash_val = text.md5_text()
		"sha256":
			hash_val = text.sha256_text()

	var label := file_path if file_path != "" else "(stdin)"
	return "%s  %s" % [hash_val, label]
