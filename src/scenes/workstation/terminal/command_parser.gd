class_name CommandParser
extends RefCounted
## Parses command line input into structured commands with pipe support.
## Handles: simple commands, pipes (|), quoted strings, redirects (>).

class ParsedCommand:
	var name: String = ""
	var args: PackedStringArray = []
	var raw: String = ""

	func get_arg(index: int, default: String = "") -> String:
		if index < args.size():
			return args[index]
		return default

	func has_flag(flag: String) -> bool:
		return flag in args

	func get_flag_value(flag: String, default: String = "") -> String:
		for i in range(args.size()):
			if args[i] == flag and i + 1 < args.size():
				return args[i + 1]
		return default


class Pipeline:
	var commands: Array[ParsedCommand] = []
	var redirect_file: String = ""  # Output redirect target (> file)
	var raw_input: String = ""

	func is_piped() -> bool:
		return commands.size() > 1


## Parse a full input line into a Pipeline (handles pipes and redirects).
static func parse(input: String) -> Pipeline:
	var pipeline := Pipeline.new()
	pipeline.raw_input = input

	# Check for output redirect first
	var redirect_parts := _split_redirect(input)
	var command_str := redirect_parts[0]
	pipeline.redirect_file = redirect_parts[1]

	# Split on pipes
	var pipe_segments := _split_pipes(command_str)

	for segment in pipe_segments:
		var cmd := _parse_single(segment.strip_edges())
		if cmd.name != "":
			pipeline.commands.append(cmd)

	return pipeline


## Parse a single command string (no pipes).
static func _parse_single(input: String) -> ParsedCommand:
	var cmd := ParsedCommand.new()
	cmd.raw = input
	var tokens := _tokenize(input)
	if tokens.is_empty():
		return cmd
	cmd.name = tokens[0].to_lower()
	for i in range(1, tokens.size()):
		cmd.args.append(tokens[i])
	return cmd


## Tokenize respecting quoted strings.
static func _tokenize(input: String) -> PackedStringArray:
	var tokens := PackedStringArray()
	var current := ""
	var in_single_quote := false
	var in_double_quote := false
	var i := 0

	while i < input.length():
		var c := input[i]

		if c == "'" and not in_double_quote:
			in_single_quote = not in_single_quote
		elif c == '"' and not in_single_quote:
			in_double_quote = not in_double_quote
		elif c == " " and not in_single_quote and not in_double_quote:
			if current != "":
				tokens.append(current)
				current = ""
		else:
			current += c
		i += 1

	if current != "":
		tokens.append(current)
	return tokens


## Split command string on pipe characters (|), respecting quotes.
static func _split_pipes(input: String) -> PackedStringArray:
	var segments := PackedStringArray()
	var current := ""
	var in_single_quote := false
	var in_double_quote := false

	for i in range(input.length()):
		var c := input[i]
		if c == "'" and not in_double_quote:
			in_single_quote = not in_single_quote
			current += c
		elif c == '"' and not in_single_quote:
			in_double_quote = not in_double_quote
			current += c
		elif c == "|" and not in_single_quote and not in_double_quote:
			segments.append(current)
			current = ""
		else:
			current += c

	if current.strip_edges() != "":
		segments.append(current)
	return segments


## Split on > for output redirect. Returns [command_part, redirect_file].
static func _split_redirect(input: String) -> Array[String]:
	var in_single_quote := false
	var in_double_quote := false

	for i in range(input.length()):
		var c := input[i]
		if c == "'" and not in_double_quote:
			in_single_quote = not in_single_quote
		elif c == '"' and not in_single_quote:
			in_double_quote = not in_double_quote
		elif c == ">" and not in_single_quote and not in_double_quote:
			var cmd_part := input.left(i).strip_edges()
			var file_part := input.substr(i + 1).strip_edges()
			return [cmd_part, file_part]

	return [input, ""]
