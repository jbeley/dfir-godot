class_name CmdCd
extends BaseCommand


func get_name() -> String:
	return "cd"


func get_description() -> String:
	return "Change working directory"


func get_usage() -> String:
	return "cd [directory]"


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	if not vfs:
		return "[color=red]No filesystem mounted.[/color]"

	var target := "/"
	if not args.is_empty():
		target = args[0]

	if vfs.set_cwd(target):
		return ""
	return "[color=red]cd: %s: No such directory[/color]" % target
