class_name IOCData
extends Resource
## An Indicator of Compromise found during investigation.

enum IOCType {
	IP_ADDRESS,
	DOMAIN,
	FILE_HASH_MD5,
	FILE_HASH_SHA256,
	EMAIL_ADDRESS,
	URL,
	FILE_PATH,
	REGISTRY_KEY,
	USER_AGENT,
	PROCESS_NAME,
}

@export var ioc_id: String = ""
@export var type: IOCType = IOCType.IP_ADDRESS
@export var value: String = ""
@export var context: String = ""  # Where/how it was found
@export var source_evidence_id: String = ""  # Which evidence it came from
@export var is_correct: bool = true  # Ground truth for scoring (hidden from player)
@export var confidence: float = 1.0  # Player's confidence level


func get_type_name() -> String:
	match type:
		IOCType.IP_ADDRESS: return "IP Address"
		IOCType.DOMAIN: return "Domain"
		IOCType.FILE_HASH_MD5: return "MD5 Hash"
		IOCType.FILE_HASH_SHA256: return "SHA256 Hash"
		IOCType.EMAIL_ADDRESS: return "Email"
		IOCType.URL: return "URL"
		IOCType.FILE_PATH: return "File Path"
		IOCType.REGISTRY_KEY: return "Registry Key"
		IOCType.USER_AGENT: return "User Agent"
		IOCType.PROCESS_NAME: return "Process"
	return "Unknown"


static func create(ioc_type: IOCType, ioc_value: String, ctx: String = "") -> IOCData:
	var ioc := IOCData.new()
	ioc.ioc_id = "ioc_%s" % ioc_value.md5_text().left(8)
	ioc.type = ioc_type
	ioc.value = ioc_value
	ioc.context = ctx
	return ioc
