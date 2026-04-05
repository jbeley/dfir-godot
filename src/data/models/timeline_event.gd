class_name TimelineEvent
extends Resource
## A single event in an incident timeline, placed by the player or auto-generated.

@export var event_id: String = ""
@export var timestamp: String = ""          # ISO 8601 format from evidence
@export var description: String = ""
@export var source_evidence_id: String = "" # Which evidence this came from
@export var technique_id: String = ""       # ATT&CK technique if applicable
@export var is_player_placed: bool = true   # Player placed vs auto-detected
@export var sort_order: int = 0             # For ordering in the timeline view


static func create(ts: String, desc: String, source: String = "") -> TimelineEvent:
	var evt := TimelineEvent.new()
	evt.event_id = "evt_%s" % desc.md5_text().left(8)
	evt.timestamp = ts
	evt.description = desc
	evt.source_evidence_id = source
	return evt
