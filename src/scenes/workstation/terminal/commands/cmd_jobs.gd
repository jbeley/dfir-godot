class_name CmdJobs
extends BaseCommand


func get_name() -> String:
	return "jobs"


func get_description() -> String:
	return "List background jobs (plaso, hayabusa, dissect)"


func get_usage() -> String:
	return "jobs [job_id]"


func execute(args: PackedStringArray, _piped_input: String = "") -> String:
	if not job_queue:
		return "[color=red]Job queue not available.[/color]"

	# Show specific job output
	if not args.is_empty():
		var job_id := args[0].to_int()
		var job := job_queue.get_job_by_id(job_id)
		if job == null:
			return "[color=red]No job with ID %d[/color]" % job_id
		if job.status == "completed":
			return job.output if job.output != "" else "[color=gray]Job completed with no output.[/color]"
		elif job.status == "running":
			return "[color=yellow]Job #%d still running (%.0f%% complete)[/color]" % [job.id, job.get_progress() * 100.0]
		elif job.status == "pending":
			return "[color=gray]Job #%d pending (waiting in queue)[/color]" % job.id
		else:
			return "[color=red]Job #%d failed[/color]" % job.id

	# List all jobs
	var all_jobs := job_queue.get_all_jobs()
	if all_jobs.is_empty():
		return "[color=gray]No jobs submitted. Use plaso, hayabusa, or dissect to submit jobs.[/color]"

	var output := "[color=yellow]Background Jobs:[/color]\n"
	for job in all_jobs:
		var status_str := ""
		match job.status:
			"pending":
				status_str = "[color=gray]PENDING[/color]"
			"running":
				status_str = "[color=yellow]RUNNING %.0f%%[/color]" % (job.get_progress() * 100.0)
			"completed":
				status_str = "[color=green]DONE[/color]"
			"failed":
				status_str = "[color=red]FAILED[/color]"

		output += "  #%d  %s  %s\n" % [job.id, status_str, job.command]

	output += "\nUse 'jobs <id>' to view completed job output."
	return output
