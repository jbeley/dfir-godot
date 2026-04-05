extends Control
## The forensic workstation - a pixel art monitor view with tabs.
## Terminal is the primary tab (terminal is king).
## Now uses the full command system with VFS, pipes, and job queue.

@onready var tab_container: TabContainer = %TabContainer
@onready var terminal_output: RichTextLabel = %TerminalOutput
@onready var terminal_input: LineEdit = %TerminalInput
@onready var status_bar: Label = %StatusBar

## Core systems
var vfs: VirtualFilesystem
var job_queue_node: JobQueue
var command_registry: Dictionary = {}  # name -> BaseCommand

## Terminal state
var command_history: Array[String] = []
var history_index: int = -1


func _ready() -> void:
	# Initialize virtual filesystem
	vfs = VirtualFilesystem.new()

	# Initialize job queue
	job_queue_node = JobQueue.new()
	job_queue_node.name = "JobQueue"
	add_child(job_queue_node)
	job_queue_node.job_completed.connect(_on_job_completed)

	# Register all commands
	_register_commands()

	# Load evidence from active case
	_mount_case_evidence()

	# Wire up UI
	terminal_input.text_submitted.connect(_on_command_submitted)
	terminal_input.grab_focus()
	_print_welcome()
	_update_status_bar()
	TimeManager.minute_changed.connect(func(_m: int): _update_status_bar())


func _register_commands() -> void:
	var commands: Array[BaseCommand] = [
		CmdHelp.new(),
		CmdLs.new(),
		CmdCat.new(),
		CmdGrep.new(),
		CmdHead.new(),
		CmdTail.new(),
		CmdSed.new(),
		CmdAwk.new(),
		CmdSort.new(),
		CmdUniq.new(),
		CmdWc.new(),
		CmdStrings.new(),
		CmdHash.new(),
		CmdFind.new(),
		CmdCd.new(),
		CmdPwd.new(),
		CmdPlaso.new(),
		CmdHayabusa.new(),
		CmdDissect.new(),
		CmdJobs.new(),
	]

	for cmd in commands:
		cmd.vfs = vfs
		cmd.job_queue = job_queue_node
		cmd.terminal = self
		command_registry[cmd.get_name()] = cmd

	# Set up help command's registry reference
	var help_cmd: CmdHelp = command_registry.get("help") as CmdHelp
	if help_cmd:
		help_cmd.set_registry(command_registry)


func _mount_case_evidence() -> void:
	if CaseManager.active_cases.is_empty():
		return

	var active_case: CaseData = CaseManager.active_cases[0]
	for evidence in active_case.evidence_items:
		if evidence.vfs_path != "" and evidence.content != "":
			vfs.write_file(evidence.vfs_path, evidence.content)


func _print_welcome() -> void:
	var tier := ReputationManager.get_tier_name()
	var case_count := CaseManager.get_active_case_count()
	_print_line("[color=cyan]╔══════════════════════════════════════════╗[/color]")
	_print_line("[color=cyan]║    DFIR Workstation v0.2.0               ║[/color]")
	_print_line("[color=cyan]║    %s[/color]" % tier.rpad(39) + "[color=cyan]║[/color]")
	_print_line("[color=cyan]╚══════════════════════════════════════════╝[/color]")
	_print_line("")
	if case_count > 0:
		_print_line("Active cases: %d | Files mounted: %d" % [case_count, vfs.get_file_count()])
	else:
		_print_line("[color=gray]No active cases. Check email for assignments.[/color]")
	_print_line("Type [color=green]help[/color] for available commands.")
	_print_line("")
	_print_prompt()


func _on_command_submitted(command: String) -> void:
	terminal_input.clear()
	if command.strip_edges() == "":
		_print_prompt()
		return

	# Add to history
	command_history.push_front(command)
	history_index = -1

	_print_line("[color=green]$ %s[/color]" % command)

	# Handle built-in commands that don't go through the registry
	var trimmed := command.strip_edges()
	match trimmed:
		"clear":
			terminal_output.clear()
			_print_prompt()
			return
		"exit", "quit":
			GameManager.change_scene("res://src/scenes/office/office.tscn")
			return
		"whoami":
			_print_line(ReputationManager.get_tier_name())
			_print_prompt()
			return
		"date":
			_print_line("%s - %s" % [TimeManager.get_day_string(), TimeManager.get_time_string()])
			_print_prompt()
			return
		"status":
			_print_status()
			_print_prompt()
			return
		"cases":
			_print_cases()
			_print_prompt()
			return

	# Parse and execute through command system (with pipe support)
	var pipeline: CommandParser.Pipeline = CommandParser.parse(trimmed)
	_execute_pipeline(pipeline)
	_print_prompt()

	# Drain work stats
	ReputationManager.work_drain(0.5)


func _execute_pipeline(pipeline: CommandParser.Pipeline) -> void:
	var piped_output := ""

	for i in range(pipeline.commands.size()):
		var parsed: CommandParser.ParsedCommand = pipeline.commands[i]
		var cmd: BaseCommand = command_registry.get(parsed.name)

		if cmd == null:
			_print_line("[color=red]Command not found: %s[/color]" % parsed.name)
			_print_line("Type 'help' for available commands.")
			return

		if not cmd.is_available():
			_print_line("[color=red]%s: requires %s rank to use[/color]" % [
				parsed.name, cmd.TIER_NAMES[cmd.get_min_tier()]
			])
			return

		piped_output = cmd.execute(parsed.args, piped_output)

	# Handle redirect
	if pipeline.redirect_file != "" and piped_output != "":
		vfs.write_file(pipeline.redirect_file, piped_output)
		_print_line("[color=gray]Output written to %s[/color]" % pipeline.redirect_file)
	elif piped_output != "":
		_print_line(piped_output)


func _print_status() -> void:
	_print_line("[color=yellow]── Analyst Status ──[/color]")
	_print_line("Title:       %s" % ReputationManager.get_tier_name())
	_print_line("Reputation:  %.0f/100" % ReputationManager.reputation)
	_print_line("Focus:       %.0f%%" % ReputationManager.focus)
	_print_line("Energy:      %.0f%%" % ReputationManager.energy)
	_print_line("Stress:      %.0f%%" % ReputationManager.stress)
	_print_line("Performance: %.0f%%" % (ReputationManager.get_performance_multiplier() * 100.0))
	_print_line("")
	_print_line("[color=yellow]── Workstation ──[/color]")
	_print_line("Filesystem:  %d files mounted" % vfs.get_file_count())
	_print_line("Jobs:        %d active, %d pending" % [
		job_queue_node.get_active_count(), job_queue_node.get_pending_count()
	])


func _print_cases() -> void:
	if CaseManager.active_cases.is_empty():
		_print_line("[color=gray]No active cases. Check your email for new assignments.[/color]")
		return
	_print_line("[color=yellow]── Active Cases ──[/color]")
	for i in range(CaseManager.active_cases.size()):
		var c: CaseData = CaseManager.active_cases[i]
		var severity_color := "white"
		match c.severity:
			CaseData.Severity.CRITICAL: severity_color = "red"
			CaseData.Severity.HIGH: severity_color = "orange"
			CaseData.Severity.MEDIUM: severity_color = "yellow"
			CaseData.Severity.LOW: severity_color = "cyan"
		_print_line("[%d] [color=%s][%s][/color] %s" % [
			i, severity_color,
			["LOW", "MEDIUM", "HIGH", "CRITICAL"][c.severity],
			c.title
		])
		_print_line("    Deadline: %.0f hours remaining | Evidence: %d items" % [
			c.get_hours_remaining(), c.evidence_items.size()
		])


func _on_job_completed(job: JobQueue.Job) -> void:
	_print_line("\n[color=green]✓ Job #%d complete: %s[/color]" % [job.id, job.command])
	_print_line("Use 'jobs %d' to view results." % job.id)
	_print_prompt()


func _print_line(text: String) -> void:
	terminal_output.append_text(text + "\n")


func _print_prompt() -> void:
	var cwd: String = vfs.get_cwd() if vfs else "~"
	terminal_output.append_text("[color=green]analyst@dfir-ws[/color]:[color=cyan]%s[/color]$ " % cwd)


func _update_status_bar() -> void:
	var jobs_text := ""
	if job_queue_node and job_queue_node.get_active_count() > 0:
		jobs_text = " | Jobs: %d" % job_queue_node.get_active_count()
	status_bar.text = "%s | %s | Cases: %d | F:%.0f E:%.0f S:%.0f%s" % [
		TimeManager.get_day_string(),
		TimeManager.get_time_string(),
		CaseManager.get_active_case_count(),
		ReputationManager.focus,
		ReputationManager.energy,
		ReputationManager.stress,
		jobs_text,
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") and not command_history.is_empty():
		history_index = mini(history_index + 1, command_history.size() - 1)
		terminal_input.text = command_history[history_index]
		terminal_input.caret_column = terminal_input.text.length()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		history_index = maxi(history_index - 1, -1)
		if history_index >= 0:
			terminal_input.text = command_history[history_index]
		else:
			terminal_input.text = ""
		terminal_input.caret_column = terminal_input.text.length()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause_game"):
		GameManager.change_scene("res://src/scenes/office/office.tscn")
