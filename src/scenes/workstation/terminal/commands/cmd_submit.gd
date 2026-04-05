class_name CmdSubmit
extends BaseCommand
## Submit the current case report for scoring.


func get_name() -> String:
	return "submit"


func get_description() -> String:
	return "Submit investigation report for the active case"


func get_usage() -> String:
	return "submit [case_index]"


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root.has_node("/root/CaseManager"):
		return "[color=red]Cannot access case manager.[/color]"

	var cm: Node = tree.root.get_node("/root/CaseManager")
	var active: Array = cm.get("active_cases")

	if active.is_empty():
		return "[color=gray]No active cases to submit.[/color]"

	var case_index := 0
	if not args.is_empty():
		case_index = args[0].to_int()

	if case_index < 0 or case_index >= active.size():
		return "[color=red]Invalid case index. Use 'cases' to list active cases.[/color]"

	var case_data: CaseData = active[case_index]

	# Score the case
	var scorer := CaseScorer.new()
	var result := scorer.score_case(case_data)

	# Apply reputation
	var rm: Node = tree.root.get_node("/root/ReputationManager")
	if rm:
		rm.call("adjust_reputation", result.reputation_earned)

	# Complete the case
	cm.call("complete_case", case_data, result.total_score)

	# Format results
	var output := "[color=yellow]╔══════════════════════════════════════╗[/color]\n"
	output += "[color=yellow]║     INVESTIGATION REPORT CARD        ║[/color]\n"
	output += "[color=yellow]╚══════════════════════════════════════╝[/color]\n\n"
	output += "Case: %s\n\n" % case_data.title

	var grade_color := "green"
	match result.grade:
		"S": grade_color = "cyan"
		"A": grade_color = "green"
		"B": grade_color = "yellow"
		"C": grade_color = "orange"
		_: grade_color = "red"

	output += "[color=%s]Grade: %s (%.0f/100)[/color]\n\n" % [grade_color, result.grade, result.total_score]

	output += "IOC Accuracy:    %.0f%%\n" % result.ioc_score
	output += "ATT&CK Mapping:  %.0f%%\n" % result.technique_score
	output += "Timeline:        %.0f%%\n" % result.timeline_score
	output += "Timeliness:      %.0f%%\n\n" % result.timeliness_score

	output += "[color=yellow]Feedback:[/color]\n"
	for line: String in result.feedback:
		output += "  - %s\n" % line

	output += "\nReputation earned: [color=green]+%.1f[/color]" % result.reputation_earned

	return output
