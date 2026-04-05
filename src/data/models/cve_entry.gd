class_name CVEEntry
extends Resource
## Represents a CVE (Common Vulnerabilities and Exposures) entry.

@export var cve_id: String = ""           # e.g. "CVE-2024-1234"
@export var description: String = ""
@export var cvss_score: float = 0.0       # 0.0 - 10.0
@export var severity: String = ""         # LOW, MEDIUM, HIGH, CRITICAL
@export var vendor: String = ""
@export var product: String = ""
@export var cwe_ids: PackedStringArray = []  # Related weakness IDs
@export var published_date: String = ""
@export var is_kev: bool = false          # In CISA Known Exploited Vulns catalog
@export var known_ransomware_use: bool = false


static func from_dict(data: Dictionary) -> CVEEntry:
	var entry := CVEEntry.new()
	entry.cve_id = data.get("cve_id", data.get("cveID", ""))
	entry.description = data.get("description", "")
	entry.cvss_score = data.get("cvss_score", 0.0)
	entry.severity = data.get("severity", "")
	entry.vendor = data.get("vendor", data.get("vendorProject", ""))
	entry.product = data.get("product", "")
	entry.published_date = data.get("published_date", data.get("dateAdded", ""))
	entry.is_kev = data.get("is_kev", false)
	entry.known_ransomware_use = data.get("knownRansomwareCampaignUse", "Unknown") == "Known"

	var cwes = data.get("cwe_ids", [])
	if cwes is Array:
		for cwe in cwes:
			entry.cwe_ids.append(str(cwe))
	return entry
