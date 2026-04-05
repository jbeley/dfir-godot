class_name CmdDissect
extends BaseCommand
## Simulates dissect.target - forensic artifact parser.
## Supports target-query, target-fs operations.

func get_name() -> String:
	return "dissect"


func get_description() -> String:
	return "Parse forensic artifacts (target-query, target-fs)"


func get_usage() -> String:
	return "dissect <subcommand> <target>\nSubcommands: query, fs, info"


func get_min_tier() -> int:
	return 2  # Analyst


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	if not is_available():
		return "[color=red]dissect: requires %s rank[/color]" % TIER_NAMES[get_min_tier()]

	if args.is_empty():
		return _show_help()

	var subcmd := args[0].to_lower()
	var sub_args := args.slice(1)

	match subcmd:
		"query":
			return _cmd_query(sub_args)
		"fs":
			return _cmd_fs(sub_args)
		"info":
			return _cmd_info(sub_args)
		_:
			return "[color=red]dissect: unknown subcommand '%s'[/color]\n%s" % [subcmd, _show_help()]


func _show_help() -> String:
	return "[color=yellow]dissect - Forensic Artifact Parser[/color]\n\n" + \
		"Usage: dissect <subcommand> <target>\n\n" + \
		"Subcommands:\n" + \
		"  query   Query parsed artifacts (registry, eventlog, etc.)\n" + \
		"  fs      Browse target filesystem\n" + \
		"  info    Show target information\n\n" + \
		"Examples:\n" + \
		"  dissect info /evidence\n" + \
		"  dissect query -f eventlog /evidence/logs\n" + \
		"  dissect fs /evidence/disk\n"


func _cmd_info(args: PackedStringArray) -> String:
	if args.is_empty():
		return "[color=red]dissect info: specify target directory[/color]"

	var target := args[0]
	if not vfs or not vfs.exists(target):
		return "[color=red]dissect: %s: target not found[/color]" % target

	var file_count := 0
	var total_size := 0
	if vfs.is_dir(target):
		for entry: String in vfs.list_dir(target):
			var path := target.rstrip("/") + "/" + entry
			if vfs.is_file(path):
				file_count += 1
				total_size += vfs.file_size(path)

	return "[color=cyan]Target Information[/color]\n" + \
		"Path:       %s\n" % target + \
		"Files:      %d\n" % file_count + \
		"Total size: %d bytes\n" % total_size + \
		"OS:         Windows (detected)\n" + \
		"Type:       forensic image"


func _cmd_query(args: PackedStringArray) -> String:
	if args.is_empty():
		return "[color=red]Usage: dissect query [-f FUNCTION] <target>[/color]\n" + \
			"Functions: eventlog, registry, services, tasks, users, network"

	var function := ""
	var target := ""

	var i := 0
	while i < args.size():
		if args[i] == "-f" and i + 1 < args.size():
			function = args[i + 1].to_lower()
			i += 2
		elif not args[i].begins_with("-"):
			target = args[i]
			i += 1
		else:
			i += 1

	if target == "":
		return "[color=red]dissect query: specify target[/color]"

	if not vfs or not vfs.exists(target):
		return "[color=red]dissect: %s: target not found[/color]" % target

	if function == "":
		return "[color=red]dissect query: specify function with -f[/color]\n" + \
			"Available: eventlog, registry, services, tasks, users, network"

	# Submit as a job since queries can be heavy
	var duration := 3.0
	var gen := _make_query_generator(target, function)
	var job := job_queue.submit_job(
		"dissect query -f %s %s" % [function, target],
		"Querying %s artifacts from %s" % [function, target],
		duration,
		gen
	)

	return "[color=yellow]Job #%d submitted: dissect query %s[/color]\nUse 'jobs' to check progress." % [job.id, function]


func _cmd_fs(args: PackedStringArray) -> String:
	if args.is_empty():
		return "[color=red]Usage: dissect fs <target>[/color]"

	var target := args[0]
	if not vfs or not vfs.exists(target):
		return "[color=red]dissect fs: %s: not found[/color]" % target

	if vfs.is_dir(target):
		var entries := vfs.list_dir_detailed(target)
		var output := "[color=cyan]Filesystem listing: %s[/color]\n" % target
		for entry: String in entries:
			output += "  %s\n" % entry
		return output

	return vfs.read_file(target)


func _make_query_generator(target: String, function: String) -> Callable:
	var fs := vfs
	return func() -> String:
		var output := "[color=cyan]dissect query results: %s[/color]\n" % function
		output += "─".repeat(50) + "\n"

		var all_content := ""
		if fs.is_file(target):
			all_content = fs.read_file(target)
		elif fs.is_dir(target):
			for entry: String in fs.list_dir(target):
				var path := target.rstrip("/") + "/" + entry
				if fs.is_file(path):
					all_content += fs.read_file(path) + "\n"

		match function:
			"eventlog":
				var count := all_content.count("EventID")
				output += "Parsed %d event log entries\n" % count
				output += all_content.left(2000)
			"registry":
				output += "Registry hive analysis:\n"
				if "HKLM" in all_content or "HKEY" in all_content:
					output += all_content.left(1500)
				else:
					output += "No registry artifacts found in target."
			"services":
				output += "Installed services:\n"
				var lines := all_content.split("\n")
				for line in lines:
					if "service" in line.to_lower() or "svc" in line.to_lower():
						output += "  %s\n" % line.strip_edges()
			"users":
				output += "User accounts:\n"
				var lines := all_content.split("\n")
				for line in lines:
					if "user" in line.to_lower() or "account" in line.to_lower() or "logon" in line.to_lower():
						output += "  %s\n" % line.strip_edges()
			_:
				output += "Function '%s' completed. Check evidence for details." % function

		return output
