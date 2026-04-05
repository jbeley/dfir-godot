extends Control
## In-game email client. Receives case assignments, client updates, and threat intel.

signal email_selected(email: Dictionary)
signal case_accepted(case_data: CaseData)

@onready var email_list: ItemList = %EmailList
@onready var subject_label: Label = %SubjectLabel
@onready var from_label: Label = %FromLabel
@onready var body_text: RichTextLabel = %BodyText
@onready var accept_btn: Button = %AcceptBtn
@onready var back_btn: Button = %BackBtn

var _emails: Array[Dictionary] = []
var _selected_index: int = -1
var _pending_cases: Dictionary = {}  # email_index -> CaseData


func _ready() -> void:
	email_list.item_selected.connect(_on_email_selected)
	accept_btn.pressed.connect(_on_accept)
	back_btn.pressed.connect(_on_back)
	accept_btn.visible = false

	_add_welcome_email()
	_generate_case_email()

	email_list.grab_focus()


func _add_welcome_email() -> void:
	_add_email({
		"from": "HR Department <hr@secureconsulting.com>",
		"subject": "Welcome to Secure Consulting!",
		"body": "Welcome to Secure Consulting, %s!\n\nYour workstation is set up and ready. Check your email regularly for new case assignments.\n\nRemember:\n- Use the terminal for forensic analysis\n- Check the evidence board to track IOCs\n- Submit your report before the deadline\n\nGood luck!\n- HR Team" % ReputationManager.get_tier_name(),
		"read": false,
		"type": "info",
	})


func _generate_case_email() -> void:
	var case_data: CaseData

	# Try campaign case first, fall back to procedural
	var campaign_case := _try_campaign_case()
	if campaign_case:
		case_data = campaign_case
	else:
		var gen := CaseGenerator.new()
		case_data = gen.generate_case(ReputationManager.career_tier)

	var email_idx := _emails.size()
	_add_email({
		"from": "%s <%s>" % [case_data.client.name, case_data.client.name.to_lower().replace(" ", ".") + "@" + case_data.client.organization.to_lower().replace(" ", "") + ".com"],
		"subject": "[URGENT] %s" % case_data.title,
		"body": "Priority: %s\nDeadline: %.0f hours\nClient: %s (%s)\n\n%s\n\nPlease accept this case to begin investigation." % [
			["Low", "Medium", "High", "CRITICAL"][case_data.severity],
			case_data.deadline_hours,
			case_data.client.name,
			case_data.client.organization,
			case_data.description,
		],
		"read": false,
		"type": "case",
	})
	_pending_cases[email_idx] = case_data


func _add_email(email: Dictionary) -> void:
	_emails.append(email)
	var prefix := "" if email.get("read", false) else "[NEW] "
	email_list.add_item("%s%s" % [prefix, email.get("subject", "No Subject")])


func _on_email_selected(index: int) -> void:
	_selected_index = index
	if index < 0 or index >= _emails.size():
		return

	var email: Dictionary = _emails[index]
	email["read"] = true
	email_list.set_item_text(index, str(email.get("subject", "")))

	from_label.text = "From: %s" % str(email.get("from", ""))
	subject_label.text = str(email.get("subject", ""))
	body_text.text = str(email.get("body", ""))

	accept_btn.visible = _pending_cases.has(index)
	email_selected.emit(email)


func _on_accept() -> void:
	if not _pending_cases.has(_selected_index):
		return

	var case_data: CaseData = _pending_cases[_selected_index]
	case_data.activate()
	CaseManager.add_case(case_data)
	_pending_cases.erase(_selected_index)
	accept_btn.visible = false

	body_text.text += "\n\n[color=green]-- CASE ACCEPTED --[/color]\nEvidence has been mounted to your workstation."
	case_accepted.emit(case_data)


func _on_back() -> void:
	GameManager.change_scene("res://src/scenes/office/office.tscn")


func _try_campaign_case() -> CaseData:
	## Try to get the next campaign case from CampaignManager.
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root.has_node("/root/CampaignManager"):
		return null

	var cm: Node = tree.root.get_node("/root/CampaignManager")
	if cm.call("is_campaign_complete"):
		return null

	var available: Array = cm.call("get_available_arcs")
	for arc_id: Variant in available:
		var next_case: Dictionary = cm.call("get_next_case_for_arc", str(arc_id))
		if next_case.is_empty():
			continue

		# Build CaseData from campaign template
		var gen := CaseGenerator.new()
		var case_data := gen.generate_case(ReputationManager.career_tier)
		case_data.title = str(next_case.get("title", case_data.title))
		case_data.description = str(next_case.get("description", case_data.description))
		case_data.story_arc_id = str(arc_id)
		case_data.deadline_hours = float(next_case.get("deadline_hours", 48.0))

		var severity_val: Variant = next_case.get("severity", 2)
		case_data.severity = int(severity_val) as CaseData.Severity

		case_data.attack_technique_ids = PackedStringArray()
		var techniques: Variant = next_case.get("techniques", [])
		if techniques is Array:
			for t: Variant in techniques as Array:
				case_data.attack_technique_ids.append(str(t))

		return case_data

	return null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_on_back()
