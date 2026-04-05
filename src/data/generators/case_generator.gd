class_name CaseGenerator
extends RefCounted
## Generates procedural DFIR cases from threat intel data and templates.

const INDUSTRIES := ["Manufacturing", "Healthcare", "Finance", "Education", "Retail", "Technology", "Government", "Energy", "Legal", "Media"]
const ORG_PREFIXES := ["Acme", "Global", "United", "Pacific", "Metro", "Summit", "Apex", "Horizon", "Quantum", "Stellar"]
const ORG_SUFFIXES := ["Corp", "Industries", "Solutions", "Group", "Systems", "Partners", "Holdings", "Technologies", "Services", "Labs"]

const SCENARIO_TEMPLATES := [
	{
		"type": "ransomware",
		"title_pattern": "Ransomware Incident - %s",
		"description": "Files encrypted across the network. Ransom note demanding cryptocurrency payment.",
		"severity": 3,  # CRITICAL
		"techniques": ["T1566.001", "T1059.001", "T1486", "T1070.001", "T1053.005"],
		"evidence_types": ["evtx", "syslog", "email", "artifact"],
		"deadline_hours": 48.0,
	},
	{
		"type": "apt",
		"title_pattern": "Suspected APT Activity - %s",
		"description": "Unusual network beaconing detected. Possible long-term compromise.",
		"severity": 3,  # CRITICAL
		"techniques": ["T1190", "T1059.001", "T1053.005", "T1071.001", "T1041"],
		"evidence_types": ["evtx", "syslog", "access_log", "artifact"],
		"deadline_hours": 72.0,
	},
	{
		"type": "insider",
		"title_pattern": "Insider Threat Investigation - %s",
		"description": "Employee suspected of exfiltrating sensitive data before resignation.",
		"severity": 2,  # HIGH
		"techniques": ["T1074.001", "T1567.002", "T1048.003", "T1083"],
		"evidence_types": ["evtx", "syslog", "access_log"],
		"deadline_hours": 36.0,
	},
	{
		"type": "phishing",
		"title_pattern": "Phishing Campaign - %s",
		"description": "Multiple employees reported suspicious emails. At least one clicked the link.",
		"severity": 2,  # HIGH
		"techniques": ["T1566.001", "T1204.002", "T1059.001", "T1547.001"],
		"evidence_types": ["evtx", "email", "syslog"],
		"deadline_hours": 24.0,
	},
	{
		"type": "brute_force",
		"title_pattern": "Brute Force Attack - %s",
		"description": "Multiple failed login attempts detected from external IP addresses.",
		"severity": 1,  # MEDIUM
		"techniques": ["T1110.001", "T1078", "T1021.001"],
		"evidence_types": ["evtx", "syslog", "access_log"],
		"deadline_hours": 24.0,
	},
]


func generate_case(difficulty: int = 0) -> CaseData:
	var template: Dictionary = SCENARIO_TEMPLATES[randi() % SCENARIO_TEMPLATES.size()]

	# Generate organization
	var org_name := "%s %s" % [
		ORG_PREFIXES[randi() % ORG_PREFIXES.size()],
		ORG_SUFFIXES[randi() % ORG_SUFFIXES.size()]
	]
	var industry: String = INDUSTRIES[randi() % INDUSTRIES.size()]

	# Create case
	var case_data := CaseData.new()
	case_data.case_id = "CASE-2024-%03d" % (randi() % 999 + 1)
	case_data.title = template["title_pattern"] % org_name
	case_data.description = template["description"]
	case_data.severity = template["severity"] as CaseData.Severity
	case_data.deadline_hours = template["deadline_hours"]

	# Scale difficulty
	var rep_reward := 5.0 + difficulty * 3.0
	case_data.reputation_reward = rep_reward

	# Generate ATT&CK technique IDs
	var techniques: Array = template["techniques"]
	for t: Variant in techniques:
		case_data.attack_technique_ids.append(str(t))

	# Generate client
	case_data.client = _generate_client(org_name, industry)

	# Generate IOCs
	var c2_ip := "%d.%d.%d.%d" % [randi() % 200 + 45, randi() % 255, randi() % 255, randi() % 254 + 1]
	var pivot_ip := "192.168.1.%d" % (randi() % 200 + 50)

	# Generate evidence
	var log_gen := LogGenerator.new()
	log_gen.malicious_ips = PackedStringArray([c2_ip, pivot_ip])
	log_gen.malicious_users = PackedStringArray(["svc_backup", "admin_temp"])
	log_gen.malicious_processes = PackedStringArray(["C:\\ProgramData\\svchost.exe", "C:\\Windows\\Temp\\update.exe"])

	var base_lines := 20 + difficulty * 10
	var evidence_types: Array = template["evidence_types"]

	for ev_type: Variant in evidence_types:
		var type_str := str(ev_type)
		match type_str:
			"evtx":
				var ev := EvidenceData.new()
				ev.evidence_id = "ev_%s_evtx" % case_data.case_id
				ev.type = EvidenceData.EvidenceType.WINDOWS_EVTX
				ev.name = "Security.evtx"
				ev.description = "Windows Security Event Log"
				ev.vfs_path = "/evidence/logs/Security.evtx"
				ev.content = log_gen.generate_windows_evtx(base_lines)
				ev.hidden_iocs = PackedStringArray([c2_ip, pivot_ip])
				case_data.evidence_items.append(ev)
			"syslog":
				var ev := EvidenceData.new()
				ev.evidence_id = "ev_%s_syslog" % case_data.case_id
				ev.type = EvidenceData.EvidenceType.LINUX_SYSLOG
				ev.name = "auth.log"
				ev.description = "Linux auth log"
				ev.vfs_path = "/evidence/logs/auth.log"
				ev.content = log_gen.generate_auth_log(base_lines)
				ev.hidden_iocs = PackedStringArray([c2_ip])
				case_data.evidence_items.append(ev)
			"access_log":
				var ev := EvidenceData.new()
				ev.evidence_id = "ev_%s_access" % case_data.case_id
				ev.type = EvidenceData.EvidenceType.APACHE_LOG
				ev.name = "access.log"
				ev.description = "Apache access log"
				ev.vfs_path = "/evidence/logs/access.log"
				ev.content = log_gen.generate_access_log(base_lines)
				ev.hidden_iocs = PackedStringArray([c2_ip])
				case_data.evidence_items.append(ev)
			"email":
				var ev := EvidenceData.new()
				ev.evidence_id = "ev_%s_email" % case_data.case_id
				ev.type = EvidenceData.EvidenceType.EMAIL
				ev.name = "suspicious_email.eml"
				ev.description = "Phishing email from employee mailbox"
				ev.vfs_path = "/evidence/email/suspicious.eml"
				ev.content = _generate_phishing_email(org_name, c2_ip)
				case_data.evidence_items.append(ev)
			"artifact":
				var ev := EvidenceData.new()
				ev.evidence_id = "ev_%s_artifact" % case_data.case_id
				ev.type = EvidenceData.EvidenceType.DISK_IMAGE
				ev.name = "malware.strings"
				ev.description = "Strings extracted from suspicious binary"
				ev.vfs_path = "/evidence/artifacts/malware.strings"
				ev.content = _generate_malware_strings(c2_ip, template["type"])
				ev.hidden_iocs = PackedStringArray([c2_ip])
				case_data.evidence_items.append(ev)

	# Ground truth IOCs
	case_data.correct_iocs.append(IOCData.create(IOCData.IOCType.IP_ADDRESS, c2_ip, "C2 server"))
	case_data.correct_iocs.append(IOCData.create(IOCData.IOCType.IP_ADDRESS, pivot_ip, "Internal pivot"))

	return case_data


func _generate_client(org_name: String, industry: String) -> ClientData:
	var client := ClientData.new()
	var personalities := [
		ClientData.Personality.PANICKED_CEO,
		ClientData.Personality.LONE_IT_ADMIN,
		ClientData.Personality.HOSTILE_LAWYER,
		ClientData.Personality.COMPETENT_CISO,
		ClientData.Personality.IT_HERO,
	]
	client.client_id = "client_%d" % (randi() % 9999)
	client.name = _random_name()
	client.organization = org_name
	client.industry = industry
	client.personality = personalities[randi() % personalities.size()]
	client.trust_level = ClientData.TrustLevel.NEUTRAL
	client.technical_level = randf_range(0.1, 0.9)
	client.stress_response = randf_range(0.2, 0.9)
	client.honesty = randf_range(0.5, 1.0)
	return client


func _random_name() -> String:
	var firsts := ["Dave", "Sarah", "Mike", "Lisa", "James", "Maria", "Robert", "Jennifer", "Carlos", "Priya"]
	var lasts := ["Morrison", "Chen", "Williams", "Patel", "Johnson", "Kim", "Brown", "Garcia", "Lee", "Taylor"]
	return "%s %s" % [firsts[randi() % firsts.size()], lasts[randi() % lasts.size()]]


func _generate_phishing_email(org_name: String, c2_ip: String) -> String:
	var domain := org_name.to_lower().replace(" ", "") + ".com"
	return """From: billing@%s-invoices.com
To: employee@%s
Date: Mon, 14 Jan 2024 16:30:00 -0500
Subject: URGENT: Invoice Payment Required
Return-Path: <bounce@mail.%s.sslip.io>

Please review the attached invoice and process payment by end of day.
You may need to enable macros to view the document.

[Attachment: Invoice_Update.xlsm]""" % [domain.left(domain.find(".")), domain, c2_ip]


func _generate_malware_strings(c2_ip: String, scenario_type: String) -> String:
	var base := """MZ
This program cannot be run in DOS mode
kernel32.dll
CreateFileW
WriteFile
WinHttpOpen
WinHttpConnect
http://%s/beacon
POST /api/checkin
User-Agent: Mozilla/5.0""" % c2_ip

	match scenario_type:
		"ransomware":
			base += """
CryptAcquireContextW
CryptEncrypt
AES-256-CBC
.encrypted
README_RESTORE.txt
vssadmin delete shadows /all /quiet"""
		"apt":
			base += """
CreateRemoteThread
VirtualAllocEx
NtQuerySystemInformation
cmd.exe /c whoami
cmd.exe /c ipconfig /all
cmd.exe /c net group "domain admins" /domain"""
		_:
			base += """
GetClipboardData
keylog.dat
screenshot.bmp"""
	return base
