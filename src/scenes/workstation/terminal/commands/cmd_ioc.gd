class_name CmdIoc
extends BaseCommand
## Track and manage Indicators of Compromise for the active case.


func get_name() -> String:
	return "ioc"


func get_description() -> String:
	return "Track indicators of compromise (IOCs)"


func get_usage() -> String:
	return "ioc add <type> <value>  |  ioc list  |  ioc types"


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root.has_node("/root/CaseManager"):
		return "[color=red]Case manager unavailable.[/color]"

	var cm: Node = tree.root.get_node("/root/CaseManager")
	var active: Array = cm.get("active_cases")

	if active.is_empty():
		return "[color=gray]No active case. Accept a case first.[/color]"

	var case_data: CaseData = active[0]

	if args.is_empty():
		return get_usage()

	var subcmd := args[0].to_lower()

	match subcmd:
		"add":
			return _add_ioc(case_data, args.slice(1))
		"list":
			return _list_iocs(case_data)
		"types":
			return _show_types()
		"remove", "rm":
			return _remove_ioc(case_data, args.slice(1))
		_:
			return "[color=red]Unknown subcommand: %s[/color]\n%s" % [subcmd, get_usage()]


func _add_ioc(case_data: CaseData, args: PackedStringArray) -> String:
	if args.size() < 2:
		return "[color=red]Usage: ioc add <type> <value>[/color]\nTypes: ip, domain, md5, sha256, email, url, filepath, regkey, useragent, process"

	var type_str := args[0].to_lower()
	var value := args[1]

	var ioc_type: IOCData.IOCType
	match type_str:
		"ip": ioc_type = IOCData.IOCType.IP_ADDRESS
		"domain": ioc_type = IOCData.IOCType.DOMAIN
		"md5": ioc_type = IOCData.IOCType.FILE_HASH_MD5
		"sha256": ioc_type = IOCData.IOCType.FILE_HASH_SHA256
		"email": ioc_type = IOCData.IOCType.EMAIL_ADDRESS
		"url": ioc_type = IOCData.IOCType.URL
		"filepath", "file": ioc_type = IOCData.IOCType.FILE_PATH
		"regkey", "reg": ioc_type = IOCData.IOCType.REGISTRY_KEY
		"useragent", "ua": ioc_type = IOCData.IOCType.USER_AGENT
		"process", "proc": ioc_type = IOCData.IOCType.PROCESS_NAME
		_:
			return "[color=red]Unknown IOC type: %s[/color]\nUse 'ioc types' to see available types." % type_str

	var context := " ".join(args.slice(2)) if args.size() > 2 else "Found during investigation"
	var ioc := IOCData.create(ioc_type, value, context)
	case_data.discovered_iocs.append(ioc)

	return "[color=green]IOC added:[/color] %s = %s" % [ioc.get_type_name(), value]


func _list_iocs(case_data: CaseData) -> String:
	if case_data.discovered_iocs.is_empty():
		return "[color=gray]No IOCs tracked yet. Use 'ioc add <type> <value>' to add one.[/color]"

	var output := "[color=yellow]── Tracked IOCs (%d) ──[/color]\n" % case_data.discovered_iocs.size()
	for i in range(case_data.discovered_iocs.size()):
		var ioc: IOCData = case_data.discovered_iocs[i]
		output += "  [%d] %-12s %s\n" % [i, ioc.get_type_name(), ioc.value]
		if ioc.context != "":
			output += "      [color=gray]%s[/color]\n" % ioc.context
	return output


func _remove_ioc(case_data: CaseData, args: PackedStringArray) -> String:
	if args.is_empty():
		return "[color=red]Usage: ioc remove <index>[/color]"
	var idx := args[0].to_int()
	if idx < 0 or idx >= case_data.discovered_iocs.size():
		return "[color=red]Invalid index. Use 'ioc list' to see IOCs.[/color]"
	var removed: IOCData = case_data.discovered_iocs[idx]
	case_data.discovered_iocs.remove_at(idx)
	return "[color=yellow]Removed IOC: %s[/color]" % removed.value


func _show_types() -> String:
	return "[color=yellow]IOC Types:[/color]\n" + \
		"  ip         IP Address\n" + \
		"  domain     Domain name\n" + \
		"  md5        MD5 file hash\n" + \
		"  sha256     SHA256 file hash\n" + \
		"  email      Email address\n" + \
		"  url        URL\n" + \
		"  filepath   File path\n" + \
		"  regkey     Registry key\n" + \
		"  useragent  User agent string\n" + \
		"  process    Process name"
