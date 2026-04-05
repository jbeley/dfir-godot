extends Control
## The forensic workstation - a pixel art monitor view with tabs.
## Terminal is the primary tab (terminal is king).

@onready var tab_container: TabContainer = %TabContainer
@onready var terminal_output: RichTextLabel = %TerminalOutput
@onready var terminal_input: LineEdit = %TerminalInput
@onready var status_bar: Label = %StatusBar

var command_history: Array[String] = []
var history_index: int = -1


func _ready() -> void:
	terminal_input.text_submitted.connect(_on_command_submitted)
	terminal_input.grab_focus()
	_print_welcome()
	_update_status_bar()
	TimeManager.minute_changed.connect(func(_m: int): _update_status_bar())


func _print_welcome() -> void:
	var tier := ReputationManager.get_tier_name()
	_print_line("[color=cyan]╔══════════════════════════════════════╗[/color]")
	_print_line("[color=cyan]║    DFIR Workstation v0.1.0           ║[/color]")
	_print_line("[color=cyan]║    %s[/color]" % tier.rpad(35) + "[color=cyan]║[/color]")
	_print_line("[color=cyan]╚══════════════════════════════════════╝[/color]")
	_print_line("")
	_print_line("Type [color=green]help[/color] for available commands.")
	_print_line("Active cases: %d" % CaseManager.get_active_case_count())
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
	_execute_command(command.strip_edges())
	_print_prompt()


func _execute_command(command: String) -> void:
	# Parse command and arguments
	var parts := command.split(" ", false)
	if parts.is_empty():
		return

	var cmd := parts[0].to_lower()
	var args := parts.slice(1)

	match cmd:
		"help":
			_cmd_help(args)
		"ls":
			_cmd_ls(args)
		"cat":
			_cmd_cat(args)
		"grep":
			_cmd_grep(args)
		"clear":
			terminal_output.clear()
		"exit", "quit":
			GameManager.change_scene("res://src/scenes/office/office.tscn")
		"whoami":
			_print_line(ReputationManager.get_tier_name())
		"date":
			_print_line("%s - %s" % [TimeManager.get_day_string(), TimeManager.get_time_string()])
		"cases":
			_cmd_cases()
		"status":
			_cmd_status()
		_:
			_print_line("[color=red]Command not found: %s[/color]" % cmd)
			_print_line("Type 'help' for available commands.")


func _cmd_help(_args: Array) -> void:
	_print_line("[color=yellow]Available commands:[/color]")
	_print_line("  help          Show this help message")
	_print_line("  ls [path]     List files in directory")
	_print_line("  cat <file>    Display file contents")
	_print_line("  grep <pat> <file>  Search for pattern in file")
	_print_line("  cases         List active cases")
	_print_line("  status        Show your current stats")
	_print_line("  whoami        Show your career title")
	_print_line("  date          Show current game date/time")
	_print_line("  clear         Clear terminal")
	_print_line("  exit          Return to office")
	_print_line("")
	_print_line("[color=gray]More tools unlock as you advance your career.[/color]")


func _cmd_ls(_args: Array) -> void:
	if CaseManager.active_cases.is_empty():
		_print_line("[color=gray]No active cases. No evidence to examine.[/color]")
		return
	_print_line("[color=gray]evidence/[/color]")
	_print_line("[color=gray]  logs/[/color]")
	_print_line("[color=gray]  memory/[/color]")
	_print_line("[color=gray]  network/[/color]")
	_print_line("[color=gray]  email/[/color]")


func _cmd_cat(_args: Array) -> void:
	if _args.is_empty():
		_print_line("[color=red]Usage: cat <filename>[/color]")
		return
	_print_line("[color=gray]No active case evidence loaded.[/color]")


func _cmd_grep(_args: Array) -> void:
	if _args.size() < 2:
		_print_line("[color=red]Usage: grep <pattern> <filename>[/color]")
		return
	_print_line("[color=gray]No active case evidence loaded.[/color]")


func _cmd_cases() -> void:
	if CaseManager.active_cases.is_empty():
		_print_line("[color=gray]No active cases. Check your email for new assignments.[/color]")
		return
	for i in range(CaseManager.active_cases.size()):
		var c = CaseManager.active_cases[i]
		_print_line("[%d] %s" % [i, c.title if c.has_method("get") else "Case %d" % i])


func _cmd_status() -> void:
	_print_line("[color=yellow]--- Analyst Status ---[/color]")
	_print_line("Title:      %s" % ReputationManager.get_tier_name())
	_print_line("Reputation: %.0f/100" % ReputationManager.reputation)
	_print_line("Focus:      %.0f%%" % ReputationManager.focus)
	_print_line("Energy:     %.0f%%" % ReputationManager.energy)
	_print_line("Stress:     %.0f%%" % ReputationManager.stress)
	_print_line("Performance: %.0f%%" % (ReputationManager.get_performance_multiplier() * 100.0))


func _print_line(text: String) -> void:
	terminal_output.append_text(text + "\n")


func _print_prompt() -> void:
	terminal_output.append_text("[color=green]analyst@dfir-ws $ [/color]")


func _update_status_bar() -> void:
	status_bar.text = "%s | %s | Cases: %d | Focus: %.0f%% | Energy: %.0f%%" % [
		TimeManager.get_day_string(),
		TimeManager.get_time_string(),
		CaseManager.get_active_case_count(),
		ReputationManager.focus,
		ReputationManager.energy,
	]


func _unhandled_input(event: InputEvent) -> void:
	# Command history navigation
	if event.is_action_pressed("ui_up") and not command_history.is_empty():
		history_index = mini(history_index + 1, command_history.size() - 1)
		terminal_input.text = command_history[history_index]
		terminal_input.caret_column = terminal_input.text.length()
	elif event.is_action_pressed("ui_down"):
		history_index = maxi(history_index - 1, -1)
		if history_index >= 0:
			terminal_input.text = command_history[history_index]
		else:
			terminal_input.text = ""
		terminal_input.caret_column = terminal_input.text.length()
	elif event.is_action_pressed("pause_game"):
		GameManager.change_scene("res://src/scenes/office/office.tscn")
