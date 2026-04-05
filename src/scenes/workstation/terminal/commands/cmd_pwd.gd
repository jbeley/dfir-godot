class_name CmdPwd
extends BaseCommand


func get_name() -> String:
	return "pwd"


func get_description() -> String:
	return "Print working directory"


func get_usage() -> String:
	return "pwd"


func execute(_args: PackedStringArray, _piped_input: String = "") -> String:
	if not vfs:
		return "/"
	return vfs.get_cwd()
