class_name EvidenceData
extends Resource
## A piece of evidence in a DFIR investigation.

enum EvidenceType {
	WINDOWS_EVTX,     # Windows Event Log
	LINUX_SYSLOG,     # Linux syslog / auth.log
	APACHE_LOG,       # Web server access/error logs
	MEMORY_DUMP,      # RAM capture artifacts
	DISK_IMAGE,       # Filesystem artifacts (MFT, prefetch, etc.)
	PCAP,             # Network packet capture
	EMAIL,            # Suspicious email (headers + body)
	REGISTRY,         # Windows registry hive exports
	FIREWALL_LOG,     # Firewall / IDS logs
	SCREENSHOT,       # Screenshot evidence
}

@export var evidence_id: String = ""
@export var type: EvidenceType = EvidenceType.LINUX_SYSLOG
@export var name: String = ""
@export var description: String = ""

## The actual content (log text, memory strings, etc.)
## For large evidence, this is the path in the virtual filesystem.
@export_multiline var content: String = ""

## IOCs hidden in this evidence that the player should find
@export var hidden_iocs: PackedStringArray = []

## Virtual filesystem path where this evidence is mounted
@export var vfs_path: String = ""

## Discovery state
var is_discovered: bool = false
var is_analyzed: bool = false


func get_type_name() -> String:
	match type:
		EvidenceType.WINDOWS_EVTX: return "Windows Event Log"
		EvidenceType.LINUX_SYSLOG: return "Linux Syslog"
		EvidenceType.APACHE_LOG: return "Apache Log"
		EvidenceType.MEMORY_DUMP: return "Memory Dump"
		EvidenceType.DISK_IMAGE: return "Disk Image"
		EvidenceType.PCAP: return "Network Capture"
		EvidenceType.EMAIL: return "Email"
		EvidenceType.REGISTRY: return "Registry Hive"
		EvidenceType.FIREWALL_LOG: return "Firewall Log"
		EvidenceType.SCREENSHOT: return "Screenshot"
	return "Unknown"
