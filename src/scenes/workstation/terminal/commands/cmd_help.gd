class_name CmdHelp
extends BaseCommand

var _registry: Dictionary = {}  # name -> BaseCommand


func set_registry(registry: Dictionary) -> void:
	_registry = registry


func get_name() -> String:
	return "help"


func get_description() -> String:
	return "Show available commands or detailed help for a specific command"


func get_usage() -> String:
	return "help [command]"


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	if args.size() > 0:
		var cmd_name := args[0].to_lower()
		if _registry.has(cmd_name):
			var cmd: BaseCommand = _registry[cmd_name]
			var output := "[color=yellow]%s[/color] - %s\n" % [cmd.get_name(), cmd.get_description()]
			output += "Usage: %s\n" % cmd.get_usage()
			if not cmd.is_available():
				output += "[color=red]Locked - requires %s rank[/color]\n" % ReputationManager.TIER_NAMES[cmd.get_min_tier()]
			return output
		return "[color=red]Unknown command: %s[/color]" % cmd_name

	var output := "[color=yellow]Available commands:[/color]\n"
	var names: Array = _registry.keys()
	names.sort()
	for cmd_name: String in names:
		var cmd: BaseCommand = _registry[cmd_name]
		var lock_indicator := "" if cmd.is_available() else " [color=red][LOCKED][/color]"
		output += "  %-12s %s%s\n" % [cmd.get_name(), cmd.get_description(), lock_indicator]
	output += "\nType 'help <command>' for detailed usage.\n"
	output += "Use | to pipe output between commands (e.g., cat file.log | grep error).\n"
	return output
