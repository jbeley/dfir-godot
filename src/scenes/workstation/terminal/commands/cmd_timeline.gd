class_name CmdTimeline
extends BaseCommand
## Add and view timeline events for the active case.


func get_name() -> String:
	return "timeline"


func get_description() -> String:
	return "Manage incident timeline events"


func get_usage() -> String:
	return "timeline add <timestamp> <description>  |  timeline list  |  timeline clear"


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root.has_node("/root/CaseManager"):
		return "[color=red]Case manager unavailable.[/color]"

	var cm: Node = tree.root.get_node("/root/CaseManager")
	var active: Array = cm.get("active_cases")

	if active.is_empty():
		return "[color=gray]No active case.[/color]"

	var case_data: CaseData = active[0]

	if args.is_empty():
		return _list_timeline(case_data)

	var subcmd := args[0].to_lower()
	match subcmd:
		"add":
			return _add_event(case_data, args.slice(1))
		"list":
			return _list_timeline(case_data)
		"clear":
			case_data.timeline_entries.clear()
			return "[color=yellow]Timeline cleared.[/color]"
		_:
			# Treat the whole thing as "add" shorthand: timeline <timestamp> <description>
			return _add_event(case_data, args)


func _add_event(case_data: CaseData, args: PackedStringArray) -> String:
	if args.size() < 2:
		return "[color=red]Usage: timeline add <timestamp> <description>[/color]\nExample: timeline add 2024-01-14T21:45 SSH brute force from 194.36.189.21"

	var timestamp := args[0]
	var description := " ".join(args.slice(1))
	var event := TimelineEvent.create(timestamp, description)
	event.is_player_placed = true
	event.sort_order = case_data.timeline_entries.size()

	case_data.timeline_entries.append(event)

	return "[color=green]Timeline event added:[/color] %s - %s" % [timestamp, description]


func _list_timeline(case_data: CaseData) -> String:
	if case_data.timeline_entries.is_empty():
		return "[color=gray]No timeline events. Use 'timeline add <timestamp> <description>' to add one.[/color]"

	# Sort by timestamp
	var entries := case_data.timeline_entries.duplicate()
	entries.sort_custom(func(a: TimelineEvent, b: TimelineEvent) -> bool:
		return a.timestamp < b.timestamp
	)

	var output := "[color=yellow]── Incident Timeline (%d events) ──[/color]\n" % entries.size()
	for i in range(entries.size()):
		var evt: TimelineEvent = entries[i]
		var marker := ">" if evt.is_player_placed else " "
		output += "  %s [color=cyan]%s[/color] %s\n" % [marker, evt.timestamp, evt.description]
	output += "\n[color=gray]> = manually added[/color]"
	return output
