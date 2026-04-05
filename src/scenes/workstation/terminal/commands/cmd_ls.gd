class_name CmdLs
extends BaseCommand


func get_name() -> String:
	return "ls"


func get_description() -> String:
	return "List directory contents"


func get_usage() -> String:
	return "ls [-l] [path]"


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	if not vfs:
		return "[color=red]No filesystem mounted. Open a case first.[/color]"

	var long_format := false
	var target_path := "."

	for arg in args:
		if arg == "-l" or arg == "-la" or arg == "-al":
			long_format = true
		elif not arg.begins_with("-"):
			target_path = arg

	if not vfs.exists(target_path):
		return "[color=red]ls: cannot access '%s': No such file or directory[/color]" % target_path

	if vfs.is_file(target_path):
		if long_format:
			return "-rw-r--r-- 1 analyst analyst %d %s" % [vfs.file_size(target_path), target_path]
		return target_path

	var entries := vfs.list_dir_detailed(target_path)
	if entries.is_empty():
		return ""

	if long_format:
		var output := "total %d\n" % entries.size()
		for entry in entries:
			var is_directory := entry.ends_with("/")
			var name := entry.rstrip("/")
			var full_path := target_path.rstrip("/") + "/" + name
			if is_directory:
				output += "drwxr-xr-x 2 analyst analyst    0 [color=cyan]%s[/color]\n" % name
			else:
				var size := vfs.file_size(full_path)
				output += "-rw-r--r-- 1 analyst analyst %4d %s\n" % [size, name]
		return output.strip_edges()

	var output := ""
	for entry in entries:
		if entry.ends_with("/"):
			output += "[color=cyan]%s[/color]  " % entry.rstrip("/")
		else:
			output += "%s  " % entry
	return output.strip_edges()
