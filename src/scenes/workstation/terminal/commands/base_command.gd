class_name BaseCommand
extends RefCounted
## Base class for all terminal commands. Subclass and override execute().

## The virtual filesystem for the current case.
var vfs: VirtualFilesystem

## The job queue for heavy operations.
var job_queue: JobQueue

## Reference to the terminal for output.
var terminal: Node


func get_name() -> String:
	return ""


func get_usage() -> String:
	return ""


func get_description() -> String:
	return ""


## Get minimum career tier required to use this command.
func get_min_tier() -> int:
	return 0  # Available from Intern


## Execute the command. Returns output as a string.
## If piped_input is non-empty, it's the output from the previous command in the pipe.
func execute(args: PackedStringArray, piped_input: String = "") -> String:
	return ""


## Check if the player has the career tier to use this command.
func is_available() -> bool:
	return ReputationManager.career_tier >= get_min_tier()


## Helper: read file content - from piped input or from a file path.
func read_input(args: PackedStringArray, piped_input: String, arg_index: int = -1) -> String:
	if piped_input != "":
		return piped_input
	# Try to find a file path in args (last non-flag argument)
	var file_path := ""
	if arg_index >= 0 and arg_index < args.size():
		file_path = args[arg_index]
	else:
		# Find last arg that doesn't start with -
		for i in range(args.size() - 1, -1, -1):
			if not args[i].begins_with("-"):
				file_path = args[i]
				break
	if file_path == "":
		return ""
	if not vfs:
		return ""
	return vfs.read_file(file_path)
