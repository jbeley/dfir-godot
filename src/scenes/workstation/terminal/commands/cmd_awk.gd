class_name CmdAwk
extends BaseCommand


func get_name() -> String:
	return "awk"


func get_description() -> String:
	return "Pattern scanning and processing (simplified)"


func get_usage() -> String:
	return "awk '{print $N}' [file]  |  awk -F',' '{print $1,$3}' [file]"


func get_min_tier() -> int:
	return 1  # Junior Analyst


func execute(args: PackedStringArray, piped_input: String = "") -> String:
	if args.is_empty():
		return "[color=red]Usage: awk [-F sep] '{print $N}' [file][/color]"

	var separator := " "
	var program := ""
	var file_path := ""

	var i := 0
	while i < args.size():
		if args[i] == "-F" and i + 1 < args.size():
			separator = args[i + 1]
			if separator.begins_with("'") or separator.begins_with('"'):
				separator = separator.trim_prefix("'").trim_suffix("'")
				separator = separator.trim_prefix('"').trim_suffix('"')
			i += 2
		elif args[i].begins_with("-F"):
			separator = args[i].substr(2)
			separator = separator.trim_prefix("'").trim_suffix("'")
			i += 1
		elif program == "":
			program = args[i]
			i += 1
		else:
			file_path = args[i]
			i += 1

	if program == "":
		return "[color=red]awk: missing program[/color]"

	# Get input
	var text := ""
	if piped_input != "":
		text = piped_input
	elif file_path != "":
		if not vfs or not vfs.exists(file_path):
			return "[color=red]awk: %s: No such file or directory[/color]" % file_path
		text = vfs.read_file(file_path)
	else:
		return "[color=red]awk: no input[/color]"

	# Parse simple print program: {print $1, $2} or {print $0}
	var fields_to_print := _parse_print_program(program)
	if fields_to_print.is_empty():
		return "[color=red]awk: only '{print $N}' programs are supported[/color]"

	var lines := text.split("\n")
	var result := PackedStringArray()

	for line in lines:
		if line.strip_edges() == "":
			continue
		var fields: PackedStringArray
		if separator == " ":
			fields = _split_whitespace(line)
		else:
			fields = line.split(separator)

		var output_fields := PackedStringArray()
		for field_num in fields_to_print:
			if field_num == 0:
				output_fields.append(line)  # $0 = whole line
			elif field_num > 0 and field_num <= fields.size():
				output_fields.append(fields[field_num - 1])
			else:
				output_fields.append("")

		result.append(" ".join(output_fields))

	return "\n".join(result)


func _parse_print_program(program: String) -> Array[int]:
	# Strip braces and quotes
	var p := program.trim_prefix("{").trim_suffix("}")
	p = p.trim_prefix("'").trim_suffix("'")
	p = p.strip_edges()

	if not p.begins_with("print ") and p != "print":
		return []

	if p == "print":
		return [0]  # Print whole line

	p = p.substr(6).strip_edges()

	var fields: Array[int] = []
	for token in p.replace(",", " ").split(" ", false):
		if token.begins_with("$"):
			var num := token.substr(1).to_int()
			fields.append(num)

	return fields


func _split_whitespace(text: String) -> PackedStringArray:
	var result := PackedStringArray()
	for part in text.split(" ", false):
		if part.strip_edges() != "":
			result.append(part.strip_edges())
	return result
