class_name CmdPlaso
extends BaseCommand
## Simulates plaso/log2timeline - timeline generation from evidence.
## Heavy operation: submits a background job.

func get_name() -> String:
	return "plaso"


func get_description() -> String:
	return "Generate forensic timeline from evidence (log2timeline + psort)"


func get_usage() -> String:
	return "plaso <evidence_dir> [-o output.csv]"


func get_min_tier() -> int:
	return 2  # Analyst


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	if not is_available():
		return "[color=red]plaso: requires %s rank to use[/color]" % ReputationManager.TIER_NAMES[get_min_tier()]

	if args.is_empty():
		return "[color=red]Usage: plaso <evidence_dir> [-o output.csv]\nGenerates a forensic timeline from all evidence in the directory.[/color]"

	var source_dir := args[0]
	var output_file := "timeline.csv"

	for i in range(args.size()):
		if args[i] == "-o" and i + 1 < args.size():
			output_file = args[i + 1]

	if not vfs or not vfs.is_dir(source_dir):
		return "[color=red]plaso: %s: No such directory[/color]" % source_dir

	# Calculate duration based on evidence size
	var file_count := 0
	var total_size := 0
	for entry: String in vfs.list_dir(source_dir):
		var path := source_dir.rstrip("/") + "/" + entry
		if vfs.is_file(path):
			file_count += 1
			total_size += vfs.file_size(path)

	if file_count == 0:
		return "[color=red]plaso: no evidence files found in %s[/color]" % source_dir

	var duration := 5.0 + file_count * 2.0 + total_size / 5000.0  # Game minutes

	# Submit background job
	var gen_callable := _make_timeline_generator(source_dir, output_file)
	var job := job_queue.submit_job(
		"plaso %s" % source_dir,
		"Generating timeline from %d files in %s" % [file_count, source_dir],
		duration,
		gen_callable
	)

	return "[color=yellow]Job #%d submitted: Timeline generation from %s[/color]\n" % [job.id, source_dir] + \
		"Estimated time: %.0f minutes. Use 'jobs' to check progress.\n" % duration + \
		"Output will be saved to: %s" % output_file


func _make_timeline_generator(source_dir: String, output_file: String) -> Callable:
	var fs := vfs
	return func() -> String:
		# Generate a CSV timeline from all evidence files
		var output := "datetime,timestamp_desc,source,sourcetype,type,user,host,message\n"
		var entries: Array[String] = []

		for entry: String in fs.list_dir(source_dir):
			var path := source_dir.rstrip("/") + "/" + entry
			if not fs.is_file(path):
				continue
			var content := fs.read_file(path)
			var lines := content.split("\n")
			for line: String in lines:
				if line.strip_edges() == "":
					continue
				# Extract timestamps from common log formats
				var ts := _extract_timestamp(line)
				if ts != "":
					entries.append("%s,Content Modification Time,%s,LOG,log entry,-,-,%s" % [
						ts, entry, line.replace(",", ";").left(200)
					])

		entries.sort()
		output += "\n".join(entries)

		# Write to VFS
		fs.write_file(output_file, output)
		return "Timeline generated: %d events -> %s" % [entries.size(), output_file]


static func _extract_timestamp(line: String) -> String:
	# Try common timestamp patterns
	# ISO 8601: 2024-01-15T14:30:00
	if line.length() > 19 and line[4] == "-" and line[7] == "-" and line[10] == "T":
		return line.left(19)
	# Syslog: Jan 15 14:30:00
	var months := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
	if line.length() > 15:
		var maybe_month := line.left(3)
		if maybe_month in months:
			return "2024-%02d-%s" % [months.find(maybe_month) + 1, line.substr(4, 11).replace(" ", "T")]
	# Windows Event Log timestamp
	if "TimeCreated" in line:
		var start := line.find("SystemTime='")
		if start >= 0:
			start += 12
			var end := line.find("'", start)
			if end > start:
				return line.substr(start, end - start)
	return ""
