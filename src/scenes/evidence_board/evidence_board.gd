extends Control
## Evidence board - drag cards, draw connections, build investigation timeline.
## Visual investigation tool for linking IOCs, evidence, and ATT&CK techniques.

signal ioc_added(ioc: IOCData)
signal connection_made(from_card: Node, to_card: Node)
signal board_closed

@onready var card_container: Control = %CardContainer
@onready var timeline_container: VBoxContainer = %TimelineContainer
@onready var ioc_list: ItemList = %IOCList
@onready var technique_list: ItemList = %TechniqueList
@onready var back_btn: Button = %BackBtn
@onready var add_ioc_btn: Button = %AddIOCBtn
@onready var ioc_type_option: OptionButton = %IOCTypeOption
@onready var ioc_value_input: LineEdit = %IOCValueInput
@onready var status_label: Label = %StatusLabel

var _cards: Array[Node] = []
var _connections: Array[Array] = []  # Array of [card_a, card_b]
var _dragging_card: Control = null
var _drag_offset := Vector2.ZERO


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	add_ioc_btn.pressed.connect(_on_add_ioc)

	# Populate IOC type dropdown
	for type_name: String in ["IP Address", "Domain", "MD5 Hash", "SHA256 Hash",
			"Email", "URL", "File Path", "Registry Key", "User Agent", "Process"]:
		ioc_type_option.add_item(type_name)

	_refresh_board()
	back_btn.grab_focus()


func _on_back() -> void:
	board_closed.emit()
	GameManager.change_scene("res://src/scenes/office/office.tscn")


func _on_add_ioc() -> void:
	var value := ioc_value_input.text.strip_edges()
	if value == "":
		status_label.text = "Enter an IOC value"
		return

	var ioc_type: IOCData.IOCType = ioc_type_option.selected as IOCData.IOCType
	var ioc := IOCData.create(ioc_type, value, "Manual entry from evidence board")
	ioc_value_input.clear()

	# Add to current case
	if not CaseManager.active_cases.is_empty():
		var active_case: CaseData = CaseManager.active_cases[0]
		active_case.discovered_iocs.append(ioc)

	_add_ioc_card(ioc)
	ioc_added.emit(ioc)
	status_label.text = "Added IOC: %s" % value


func _refresh_board() -> void:
	# Clear existing
	for child in card_container.get_children():
		child.queue_free()
	_cards.clear()
	ioc_list.clear()
	technique_list.clear()

	if CaseManager.active_cases.is_empty():
		status_label.text = "No active case. Accept a case first."
		return

	var active_case: CaseData = CaseManager.active_cases[0]
	status_label.text = "Case: %s" % active_case.title

	# Add evidence cards
	for evidence in active_case.evidence_items:
		_add_evidence_card(evidence)

	# Add discovered IOCs
	for ioc in active_case.discovered_iocs:
		_add_ioc_card(ioc)

	# Show mapped techniques
	for tech_id in active_case.mapped_techniques:
		technique_list.add_item(tech_id)


func _add_evidence_card(evidence: EvidenceData) -> void:
	var card := _create_card(evidence.name, evidence.get_type_name(), Color(0.2, 0.4, 0.6))
	card.set_meta("evidence", evidence)
	card_container.add_child(card)
	_cards.append(card)


func _add_ioc_card(ioc: IOCData) -> void:
	var card := _create_card(ioc.value, ioc.get_type_name(), Color(0.6, 0.2, 0.2))
	card.set_meta("ioc", ioc)
	card_container.add_child(card)
	_cards.append(card)
	ioc_list.add_item("%s: %s" % [ioc.get_type_name(), ioc.value])


func _create_card(title: String, subtitle: String, bg_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(100, 40)
	card.position = Vector2(randf_range(20, 300), randf_range(20, 150))

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = bg_color.lightened(0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(4)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	var title_label := Label.new()
	title_label.text = title.left(20)
	title_label.add_theme_font_size_override("font_size", 8)
	vbox.add_child(title_label)

	var sub_label := Label.new()
	sub_label.text = subtitle
	sub_label.add_theme_font_size_override("font_size", 6)
	sub_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(sub_label)

	# Make draggable
	card.gui_input.connect(_on_card_input.bind(card))

	return card


func _on_card_input(event: InputEvent, card: Control) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging_card = card
				_drag_offset = card.position - event.global_position
				card.move_to_front()
			else:
				_dragging_card = null
	elif event is InputEventMouseMotion and _dragging_card == card:
		card.position = event.global_position + _drag_offset


func _draw() -> void:
	# Draw connections between cards
	for conn: Array in _connections:
		if conn.size() >= 2 and is_instance_valid(conn[0]) and is_instance_valid(conn[1]):
			var from_card: Control = conn[0] as Control
			var to_card: Control = conn[1] as Control
			var from_pos: Vector2 = from_card.position + from_card.size / 2.0
			var to_pos: Vector2 = to_card.position + to_card.size / 2.0
			draw_line(from_pos, to_pos, Color(0.8, 0.8, 0.2, 0.6), 1.0)
