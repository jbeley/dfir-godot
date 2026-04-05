class_name CmdHayabusa
extends BaseCommand
## Simulates Hayabusa - Windows Event Log analysis with Sigma-like rules.
## Heavy operation: submits a background job.

# Built-in detection rules (simplified Sigma-like)
const BUILTIN_RULES := [
	{
		"name": "Suspicious PowerShell Execution",
		"level": "high",
		"event_id": "4104",
		"keywords": ["Invoke-Expression", "IEX", "DownloadString", "Net.WebClient", "bypass", "-enc", "FromBase64"],
		"description": "Detects suspicious PowerShell commands commonly used in attacks",
	},
	{
		"name": "Suspicious Process Creation",
		"level": "medium",
		"event_id": "4688",
		"keywords": ["cmd.exe", "powershell.exe", "wscript.exe", "cscript.exe", "mshta.exe", "certutil.exe", "bitsadmin.exe"],
		"description": "Detects creation of commonly abused processes",
	},
	{
		"name": "Account Logon Failure Brute Force",
		"level": "high",
		"event_id": "4625",
		"keywords": [],
		"description": "Detects multiple failed logon attempts (potential brute force)",
		"threshold": 5,
	},
	{
		"name": "New Service Installed",
		"level": "medium",
		"event_id": "7045",
		"keywords": [],
		"description": "Detects new service installation (potential persistence)",
	},
	{
		"name": "Scheduled Task Created",
		"level": "medium",
		"event_id": "4698",
		"keywords": [],
		"description": "Detects scheduled task creation (potential persistence)",
	},
	{
		"name": "User Account Created",
		"level": "low",
		"event_id": "4720",
		"keywords": [],
		"description": "Detects creation of new user accounts",
	},
	{
		"name": "Audit Log Cleared",
		"level": "critical",
		"event_id": "1102",
		"keywords": [],
		"description": "Detects clearing of Windows Event Logs (anti-forensics)",
	},
	{
		"name": "RDP Logon",
		"level": "low",
		"event_id": "4624",
		"keywords": ["LogonType='10'", "LogonType='3'"],
		"description": "Detects Remote Desktop (RDP) logon sessions",
	},
	{
		"name": "Lateral Movement via PsExec",
		"level": "high",
		"event_id": "7045",
		"keywords": ["PSEXESVC", "psexec"],
		"description": "Detects PsExec service installation for lateral movement",
	},
	{
		"name": "Mimikatz Activity",
		"level": "critical",
		"event_id": "4688",
		"keywords": ["mimikatz", "sekurlsa", "lsadump", "privilege::debug", "token::elevate"],
		"description": "Detects Mimikatz credential dumping tool usage",
	},
]


func get_name() -> String:
	return "hayabusa"


func get_description() -> String:
	return "Windows Event Log threat hunting with detection rules"


func get_usage() -> String:
	return "hayabusa <evtx_file_or_dir> [-l LEVEL] [-r RULE]"


func get_min_tier() -> int:
	return 1  # Junior Analyst


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	if not is_available():
		return "[color=red]hayabusa: requires %s rank[/color]" % ReputationManager.TIER_NAMES[get_min_tier()]

	if args.is_empty():
		return _show_usage()

	var target := args[0]
	var min_level := "low"
	var specific_rule := ""

	var i := 1
	while i < args.size():
		if args[i] == "-l" and i + 1 < args.size():
			min_level = args[i + 1].to_lower()
			i += 2
		elif args[i] == "-r" and i + 1 < args.size():
			specific_rule = args[i + 1]
			i += 2
		elif args[i] == "--rules":
			return _list_rules()
		else:
			i += 1

	if not vfs:
		return "[color=red]No filesystem mounted.[/color]"

	if not vfs.exists(target):
		return "[color=red]hayabusa: %s: No such file or directory[/color]" % target

	var duration := 8.0 if vfs.is_dir(target) else 3.0

	var gen := _make_scan_generator(target, min_level, specific_rule)
	var job := job_queue.submit_job(
		"hayabusa %s" % target,
		"Scanning %s with %d detection rules" % [target, BUILTIN_RULES.size()],
		duration,
		gen
	)

	return "[color=yellow]Job #%d submitted: Hayabusa scan of %s[/color]\n" % [job.id, target] + \
		"Rules: %d | Min level: %s\n" % [BUILTIN_RULES.size(), min_level] + \
		"Use 'jobs' to check progress."


func _show_usage() -> String:
	var output := "[color=yellow]Hayabusa - Windows Event Log Analyzer[/color]\n\n"
	output += "Usage: hayabusa <evtx_file_or_dir> [-l LEVEL] [-r RULE]\n\n"
	output += "Options:\n"
	output += "  -l LEVEL    Minimum alert level (low/medium/high/critical)\n"
	output += "  -r RULE     Run only a specific rule by name\n"
	output += "  --rules     List all available detection rules\n"
	return output


func _list_rules() -> String:
	var output := "[color=yellow]Detection Rules (%d):[/color]\n" % BUILTIN_RULES.size()
	for rule: Dictionary in BUILTIN_RULES:
		var level: String = rule["level"]
		var color := _level_color(level)
		output += "  [color=%s][%s][/color] %s (EventID: %s)\n" % [
			color, level.to_upper(), rule["name"], rule["event_id"]
		]
	return output


func _make_scan_generator(target: String, min_level: String, specific_rule: String) -> Callable:
	var fs := vfs
	return func() -> String:
		# Collect all log content
		var all_content := ""
		if fs.is_file(target):
			all_content = fs.read_file(target)
		else:
			for entry: String in fs.list_dir(target):
				var path := target.rstrip("/") + "/" + entry
				if fs.is_file(path):
					all_content += fs.read_file(path) + "\n"

		var lines := all_content.split("\n")
		var alerts: Array[String] = []
		var level_priority := {"low": 0, "medium": 1, "high": 2, "critical": 3}
		var min_priority: int = level_priority.get(min_level, 0)

		for rule: Dictionary in BUILTIN_RULES:
			var rule_name: String = rule["name"]
			var rule_level: String = rule["level"]
			if specific_rule != "" and rule_name != specific_rule:
				continue
			var rule_priority: int = level_priority.get(rule_level, 0)
			if rule_priority < min_priority:
				continue

			var rule_matches := 0
			for line: String in lines:
				if _line_matches_rule(line, rule):
					rule_matches += 1
					var color := _level_color(rule_level)
					alerts.append("[color=%s][%s][/color] %s | %s" % [
						color, rule_level.to_upper(), rule_name,
						line.strip_edges().left(120)
					])

		if alerts.is_empty():
			return "[color=green]Scan complete. No alerts detected.[/color]"

		var output := "[color=yellow]Hayabusa Scan Results: %d alerts[/color]\n" % alerts.size()
		output += "─".repeat(60) + "\n"
		for alert: String in alerts:
			output += alert + "\n"
		output += "─".repeat(60) + "\n"
		output += "Total: %d alerts" % alerts.size()
		return output


static func _line_matches_rule(line: String, rule: Dictionary) -> bool:
	var event_id: String = rule["event_id"]
	var keywords: Array = rule.get("keywords", [])

	# Check if line contains the event ID
	if event_id != "" and ("EventID" in line or "event_id" in line or "Event ID" in line):
		if event_id in line:
			if keywords.is_empty():
				return true
			for keyword: String in keywords:
				if keyword.to_lower() in line.to_lower():
					return true
	return false


static func _level_color(level: String) -> String:
	match level:
		"critical": return "red"
		"high": return "orange"
		"medium": return "yellow"
		"low": return "cyan"
	return "white"
