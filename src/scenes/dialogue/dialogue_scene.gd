extends Control
## Dialogue scene - displays NPC conversations with player choices.

@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var portrait_rect: ColorRect = %PortraitRect
@onready var portrait_sprite: Sprite2D = %PortraitSprite
@onready var continue_label: Label = %ContinueLabel

var _dialogue: DialogueManager
var _return_scene: String = "res://src/scenes/office/office.tscn"
var _client: ClientData
var _typing_timer: float = 0.0
var _full_text: String = ""
var _shown_chars: int = 0
var _typing_speed: float = 30.0  # chars per second
var _is_typing: bool = false


func _ready() -> void:
	_dialogue = DialogueManager.new()
	_dialogue.node_displayed.connect(_on_node_displayed)
	_dialogue.dialogue_ended.connect(_on_dialogue_ended)
	_dialogue.trust_changed.connect(_on_trust_changed)
	_dialogue.evidence_revealed.connect(_on_evidence_revealed)

	continue_label.visible = false

	# Load dialogue based on active case
	_load_case_dialogue()


func _process(delta: float) -> void:
	if _is_typing:
		_typing_timer += delta * _typing_speed
		var new_chars := int(_typing_timer)
		if new_chars > _shown_chars:
			_shown_chars = mini(new_chars, _full_text.length())
			dialogue_text.text = _full_text.left(_shown_chars)
			if _shown_chars >= _full_text.length():
				_is_typing = false
				_show_choices_or_continue()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if _is_typing:
			# Skip typing animation
			_is_typing = false
			_shown_chars = _full_text.length()
			dialogue_text.text = _full_text
			_show_choices_or_continue()
		elif continue_label.visible:
			# Auto-advance was waiting for input
			var node := _dialogue.get_current_node()
			if node and node.next_id != "" and node.choices.is_empty():
				continue_label.visible = false
				if node.next_id == "end":
					_on_dialogue_ended()
				else:
					_dialogue._advance_to(node.next_id)
	elif event.is_action_pressed("pause_game"):
		_on_dialogue_ended()


func _load_case_dialogue() -> void:
	if CaseManager.active_cases.is_empty():
		_show_no_case()
		return

	var case_data: CaseData = CaseManager.active_cases[0]
	_client = case_data.client

	# Load portrait based on personality
	if _client:
		var portrait_path := ""
		match _client.personality:
			ClientData.Personality.PANICKED_CEO:
				portrait_path = "res://assets/sprites/characters/portraits/panicked_ceo.png"
				portrait_rect.color = Color(0.6, 0.3, 0.3)
			ClientData.Personality.LONE_IT_ADMIN:
				portrait_path = "res://assets/sprites/characters/portraits/it_admin.png"
				portrait_rect.color = Color(0.3, 0.4, 0.6)
			ClientData.Personality.HOSTILE_LAWYER:
				portrait_path = "res://assets/sprites/characters/portraits/hostile_lawyer.png"
				portrait_rect.color = Color(0.5, 0.3, 0.5)
			ClientData.Personality.COMPETENT_CISO:
				portrait_path = "res://assets/sprites/characters/portraits/competent_ciso.png"
				portrait_rect.color = Color(0.3, 0.5, 0.3)
			ClientData.Personality.IT_HERO:
				portrait_path = "res://assets/sprites/characters/portraits/it_hero.png"
				portrait_rect.color = Color(0.4, 0.4, 0.5)
		if portrait_path != "" and ResourceLoader.exists(portrait_path):
			portrait_sprite.texture = load(portrait_path)

	# Load dialogue file
	var dialogue_path := "res://assets/data/dialogue/panicked_ceo_ransomware.json"
	if ResourceLoader.exists(dialogue_path):
		var file := FileAccess.open(dialogue_path, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				_dialogue.load_dialogue(json.data)
				_dialogue.start("start")
			else:
				_show_generic_dialogue()
		else:
			_show_generic_dialogue()
	else:
		_show_generic_dialogue()


func _show_generic_dialogue() -> void:
	var data: Array = [
		{"id": "start", "speaker": "Client", "text": "Thanks for taking our case. We need your help.", "next": "end"},
	]
	_dialogue.load_dialogue(data)
	_dialogue.start("start")


func _show_no_case() -> void:
	speaker_label.text = "System"
	dialogue_text.text = "No active case. Accept a case from your email first."
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_on_dialogue_ended)
	choices_container.add_child(back_btn)
	back_btn.grab_focus()


func _show_error(msg: String) -> void:
	speaker_label.text = "Error"
	dialogue_text.text = msg


func _on_node_displayed(node: DialogueManager.DialogueNode) -> void:
	# Clear old choices
	for child: Node in choices_container.get_children():
		child.queue_free()

	speaker_label.text = node.speaker
	continue_label.visible = false

	# Start typewriter effect
	_full_text = node.text
	_shown_chars = 0
	_typing_timer = 0.0
	_is_typing = true
	dialogue_text.text = ""

	SfxBank.play("notification")


func _show_choices_or_continue() -> void:
	var node := _dialogue.get_current_node()
	if node == null:
		return

	if not node.choices.is_empty():
		# Show choice buttons
		for i in range(node.choices.size()):
			var choice: DialogueManager.DialogueChoice = node.choices[i]
			var btn := Button.new()
			btn.text = choice.text
			btn.pressed.connect(_on_choice_pressed.bind(i))
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choices_container.add_child(btn)
			if i == 0:
				btn.call_deferred("grab_focus")
	elif node.next_id != "" and node.next_id != "end":
		# Show "press E to continue"
		continue_label.text = "[E] Continue"
		continue_label.visible = true
	elif node.next_id == "end" or node.next_id == "":
		continue_label.text = "[E] End conversation"
		continue_label.visible = true


func _on_choice_pressed(index: int) -> void:
	SfxBank.play("menu_select")
	_dialogue.select_choice(index)


func _on_dialogue_ended() -> void:
	GameManager.change_scene(_return_scene)


func _on_trust_changed(amount: float) -> void:
	if CaseManager.active_cases.is_empty():
		return
	var case_data: CaseData = CaseManager.active_cases[0]
	if case_data.client:
		# Adjust trust level based on accumulated trust
		if amount > 0:
			if case_data.client.trust_level < ClientData.TrustLevel.TRUSTING:
				case_data.client.trust_level = (case_data.client.trust_level + 1) as ClientData.TrustLevel


func _on_evidence_revealed(_evidence_id: String) -> void:
	# Evidence is already mounted but we can show a notification
	pass
