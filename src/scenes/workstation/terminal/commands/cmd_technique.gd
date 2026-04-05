class_name CmdTechnique
extends BaseCommand
## Map ATT&CK techniques to the active case.


func get_name() -> String:
	return "technique"


func get_description() -> String:
	return "Map MITRE ATT&CK techniques to the case"


func get_usage() -> String:
	return "technique add <T1234.001>  |  technique list  |  technique search <keyword>"


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root.has_node("/root/CaseManager"):
		return "[color=red]Case manager unavailable.[/color]"

	var cm: Node = tree.root.get_node("/root/CaseManager")
	var active: Array = cm.get("active_cases")

	if active.is_empty():
		return "[color=gray]No active case.[/color]"

	var case_data: CaseData = active[0]

	if args.is_empty():
		return _list_mapped(case_data)

	var subcmd := args[0].to_lower()
	match subcmd:
		"add":
			return _add_technique(case_data, args.slice(1))
		"list":
			return _list_mapped(case_data)
		"remove", "rm":
			return _remove_technique(case_data, args.slice(1))
		"search":
			return _search_techniques(args.slice(1))
		"tactics":
			return _show_tactics()
		_:
			# If it looks like a technique ID, treat as add
			if args[0].begins_with("T") or args[0].begins_with("t"):
				return _add_technique(case_data, args)
			return "[color=red]Unknown subcommand.[/color]\n" + get_usage()


func _add_technique(case_data: CaseData, args: PackedStringArray) -> String:
	if args.is_empty():
		return "[color=red]Usage: technique add T1059.001[/color]"

	var tech_id := args[0].to_upper()
	if not tech_id.begins_with("T"):
		tech_id = "T" + tech_id

	if tech_id in case_data.mapped_techniques:
		return "[color=yellow]%s already mapped.[/color]" % tech_id

	case_data.mapped_techniques.append(tech_id)
	return "[color=green]Technique mapped:[/color] %s" % tech_id


func _remove_technique(case_data: CaseData, args: PackedStringArray) -> String:
	if args.is_empty():
		return "[color=red]Usage: technique remove T1059.001[/color]"
	var tech_id := args[0].to_upper()
	var idx := -1
	for i in range(case_data.mapped_techniques.size()):
		if case_data.mapped_techniques[i] == tech_id:
			idx = i
			break
	if idx == -1:
		return "[color=red]%s not mapped.[/color]" % tech_id
	case_data.mapped_techniques.remove_at(idx)
	return "[color=yellow]Removed %s[/color]" % tech_id


func _list_mapped(case_data: CaseData) -> String:
	if case_data.mapped_techniques.is_empty():
		return "[color=gray]No techniques mapped. Use 'technique add T1059.001' to add one.[/color]"

	var output := "[color=yellow]── Mapped ATT&CK Techniques (%d) ──[/color]\n" % case_data.mapped_techniques.size()
	for tech_id: String in case_data.mapped_techniques:
		output += "  %s\n" % tech_id
	return output


func _search_techniques(_args: PackedStringArray) -> String:
	return "[color=yellow]Common techniques:[/color]\n" + \
		"  T1566.001  Phishing: Spearphishing Attachment\n" + \
		"  T1059.001  PowerShell\n" + \
		"  T1053.005  Scheduled Task\n" + \
		"  T1547.001  Registry Run Keys / Startup Folder\n" + \
		"  T1078      Valid Accounts\n" + \
		"  T1110.001  Brute Force: Password Guessing\n" + \
		"  T1021.001  Remote Desktop Protocol\n" + \
		"  T1486      Data Encrypted for Impact (Ransomware)\n" + \
		"  T1070.001  Indicator Removal: Clear Event Logs\n" + \
		"  T1071.001  Application Layer Protocol: Web\n" + \
		"  T1041      Exfiltration Over C2 Channel\n" + \
		"  T1190      Exploit Public-Facing Application\n" + \
		"  T1204.002  User Execution: Malicious File\n" + \
		"  T1083      File and Directory Discovery\n" + \
		"  T1048.003  Exfiltration Over Unencrypted Protocol\n"


func _show_tactics() -> String:
	return "[color=yellow]ATT&CK Tactics:[/color]\n" + \
		"  1. Reconnaissance\n" + \
		"  2. Resource Development\n" + \
		"  3. Initial Access\n" + \
		"  4. Execution\n" + \
		"  5. Persistence\n" + \
		"  6. Privilege Escalation\n" + \
		"  7. Defense Evasion\n" + \
		"  8. Credential Access\n" + \
		"  9. Discovery\n" + \
		"  10. Lateral Movement\n" + \
		"  11. Collection\n" + \
		"  12. Command and Control\n" + \
		"  13. Exfiltration\n" + \
		"  14. Impact\n"
