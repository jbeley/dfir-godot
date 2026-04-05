class_name CasePackLoader
extends RefCounted
## Loads custom case packs from JSON files.
## Case packs can be placed in user://case_packs/ or res://assets/data/case_packs/
##
## Case Pack JSON Format:
## {
##   "pack_info": {
##     "name": "My Case Pack",
##     "author": "username",
##     "version": "1.0",
##     "description": "A set of custom DFIR cases"
##   },
##   "cases": [
##     {
##       "title": "Case Title",
##       "description": "What happened",
##       "severity": "HIGH",
##       "deadline_hours": 48,
##       "reputation_reward": 8.0,
##       "attack_techniques": ["T1566.001", "T1059.001"],
##       "client": {
##         "name": "Jane Doe",
##         "title": "CTO",
##         "organization": "TechCorp",
##         "personality": "competent_ciso"
##       },
##       "evidence": [
##         {
##           "name": "auth.log",
##           "type": "linux_syslog",
##           "path": "/evidence/logs/auth.log",
##           "content": "Jan 15 ... (log content)"
##         }
##       ],
##       "correct_iocs": [
##         {"type": "ip", "value": "10.0.0.1", "context": "C2 server"}
##       ]
##     }
##   ]
## }

const USER_PACKS_DIR := "user://case_packs"
const BUNDLED_PACKS_DIR := "res://assets/data/case_packs"


func get_available_packs() -> Array[Dictionary]:
	var packs: Array[Dictionary] = []

	# Check bundled packs
	_scan_directory(BUNDLED_PACKS_DIR, packs)

	# Check user packs
	_scan_directory(USER_PACKS_DIR, packs)

	return packs


func _scan_directory(dir_path: String, packs: Array[Dictionary]) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var info := _read_pack_info(dir_path.path_join(file_name))
			if not info.is_empty():
				info["file_path"] = dir_path.path_join(file_name)
				packs.append(info)
		file_name = dir.get_next()


func _read_pack_info(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var data: Dictionary = json.data
	return data.get("pack_info", {})


func load_pack(path: String) -> Array[CaseData]:
	var cases: Array[CaseData] = []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open case pack: %s" % path)
		return cases

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Invalid JSON in case pack: %s" % path)
		return cases

	var data: Dictionary = json.data
	var case_array: Variant = data.get("cases", [])
	if not case_array is Array:
		return cases

	for case_dict: Variant in case_array as Array:
		var cd: Dictionary = case_dict as Dictionary
		var case_data := _parse_case(cd)
		if case_data:
			cases.append(case_data)

	return cases


func _parse_case(data: Dictionary) -> CaseData:
	var case_data := CaseData.new()
	case_data.case_id = "MOD-%s" % str(data.get("title", "unknown")).md5_text().left(8)
	case_data.title = str(data.get("title", "Untitled Case"))
	case_data.description = str(data.get("description", ""))
	case_data.deadline_hours = float(data.get("deadline_hours", 48.0))
	case_data.reputation_reward = float(data.get("reputation_reward", 5.0))

	# Severity
	var sev: String = str(data.get("severity", "MEDIUM")).to_upper()
	match sev:
		"LOW": case_data.severity = CaseData.Severity.LOW
		"MEDIUM": case_data.severity = CaseData.Severity.MEDIUM
		"HIGH": case_data.severity = CaseData.Severity.HIGH
		"CRITICAL": case_data.severity = CaseData.Severity.CRITICAL

	# ATT&CK techniques
	var techniques: Variant = data.get("attack_techniques", [])
	if techniques is Array:
		for t: Variant in techniques as Array:
			case_data.attack_technique_ids.append(str(t))

	# Client
	var client_data: Variant = data.get("client", {})
	if client_data is Dictionary:
		case_data.client = _parse_client(client_data as Dictionary)

	# Evidence
	var evidence_array: Variant = data.get("evidence", [])
	if evidence_array is Array:
		for ev_dict: Variant in evidence_array as Array:
			var ev := _parse_evidence(ev_dict as Dictionary)
			if ev:
				case_data.evidence_items.append(ev)

	# Correct IOCs
	var ioc_array: Variant = data.get("correct_iocs", [])
	if ioc_array is Array:
		for ioc_dict: Variant in ioc_array as Array:
			var ioc := _parse_ioc(ioc_dict as Dictionary)
			if ioc:
				case_data.correct_iocs.append(ioc)

	return case_data


func _parse_client(data: Dictionary) -> ClientData:
	var client := ClientData.new()
	client.name = str(data.get("name", "Client"))
	client.title = str(data.get("title", ""))
	client.organization = str(data.get("organization", ""))

	var personality: String = str(data.get("personality", "panicked_ceo")).to_lower()
	match personality:
		"panicked_ceo": client.personality = ClientData.Personality.PANICKED_CEO
		"lone_it_admin", "it_admin": client.personality = ClientData.Personality.LONE_IT_ADMIN
		"hostile_lawyer": client.personality = ClientData.Personality.HOSTILE_LAWYER
		"competent_ciso", "ciso": client.personality = ClientData.Personality.COMPETENT_CISO
		"it_hero": client.personality = ClientData.Personality.IT_HERO

	return client


func _parse_evidence(data: Dictionary) -> EvidenceData:
	var ev := EvidenceData.new()
	ev.name = str(data.get("name", "evidence"))
	ev.description = str(data.get("description", ""))
	ev.vfs_path = str(data.get("path", "/evidence/" + ev.name))
	ev.content = str(data.get("content", ""))

	var type_str: String = str(data.get("type", "linux_syslog")).to_lower()
	match type_str:
		"windows_evtx", "evtx": ev.type = EvidenceData.EvidenceType.WINDOWS_EVTX
		"linux_syslog", "syslog", "auth": ev.type = EvidenceData.EvidenceType.LINUX_SYSLOG
		"apache_log", "access_log", "apache": ev.type = EvidenceData.EvidenceType.APACHE_LOG
		"memory_dump", "memory": ev.type = EvidenceData.EvidenceType.MEMORY_DUMP
		"disk_image", "disk": ev.type = EvidenceData.EvidenceType.DISK_IMAGE
		"pcap", "network": ev.type = EvidenceData.EvidenceType.PCAP
		"email": ev.type = EvidenceData.EvidenceType.EMAIL
		"registry": ev.type = EvidenceData.EvidenceType.REGISTRY
		"firewall_log", "firewall": ev.type = EvidenceData.EvidenceType.FIREWALL_LOG

	return ev


func _parse_ioc(data: Dictionary) -> IOCData:
	var type_str: String = str(data.get("type", "ip")).to_lower()
	var value: String = str(data.get("value", ""))
	var context: String = str(data.get("context", ""))

	var ioc_type: IOCData.IOCType
	match type_str:
		"ip": ioc_type = IOCData.IOCType.IP_ADDRESS
		"domain": ioc_type = IOCData.IOCType.DOMAIN
		"md5": ioc_type = IOCData.IOCType.FILE_HASH_MD5
		"sha256": ioc_type = IOCData.IOCType.FILE_HASH_SHA256
		"email": ioc_type = IOCData.IOCType.EMAIL_ADDRESS
		"url": ioc_type = IOCData.IOCType.URL
		"filepath", "file": ioc_type = IOCData.IOCType.FILE_PATH
		"regkey": ioc_type = IOCData.IOCType.REGISTRY_KEY
		"useragent": ioc_type = IOCData.IOCType.USER_AGENT
		"process": ioc_type = IOCData.IOCType.PROCESS_NAME
		_: ioc_type = IOCData.IOCType.IP_ADDRESS

	return IOCData.create(ioc_type, value, context)
