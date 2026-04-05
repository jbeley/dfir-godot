class_name JobQueue
extends Node
## Background job system for heavy forensic operations.
## Jobs consume game-time and can run concurrently (up to max_concurrent).

signal job_started(job: Job)
signal job_completed(job: Job)
signal job_progress(job: Job, percent: float)
signal job_failed(job: Job, error: String)

var max_concurrent: int = 2  # Upgradeable with better hardware
var _active_jobs: Array[Job] = []
var _pending_jobs: Array[Job] = []
var _completed_jobs: Array[Job] = []
var _next_id: int = 1


class Job:
	var id: int = 0
	var command: String = ""
	var description: String = ""
	var duration_minutes: float = 10.0  # Game-time minutes to complete
	var elapsed_minutes: float = 0.0
	var output: String = ""
	var status: String = "pending"  # pending, running, completed, failed
	var callback: Callable  # Called with (Job) when complete
	var progress_callback: Callable  # Called with (Job, float) for progress updates

	func get_progress() -> float:
		if duration_minutes <= 0:
			return 1.0
		return clampf(elapsed_minutes / duration_minutes, 0.0, 1.0)

	func is_done() -> bool:
		return status == "completed" or status == "failed"


func _ready() -> void:
	TimeManager.minute_changed.connect(_on_game_minute)


func submit_job(command: String, description: String, duration: float,
		output_generator: Callable, on_complete: Callable = Callable()) -> Job:
	var job := Job.new()
	job.id = _next_id
	_next_id += 1
	job.command = command
	job.description = description
	job.duration_minutes = duration
	job.callback = on_complete
	# Store the output generator to call when the job finishes
	job.set_meta("output_generator", output_generator)

	_pending_jobs.append(job)
	_try_start_next()
	return job


func _try_start_next() -> void:
	while _active_jobs.size() < max_concurrent and not _pending_jobs.is_empty():
		var job := _pending_jobs.pop_front() as Job
		job.status = "running"
		_active_jobs.append(job)
		job_started.emit(job)


func _on_game_minute(_minute: int) -> void:
	var performance := ReputationManager.get_performance_multiplier()
	var finished: Array[Job] = []

	for job in _active_jobs:
		job.elapsed_minutes += performance  # Better stats = faster processing
		var progress := job.get_progress()
		job_progress.emit(job, progress)

		if progress >= 1.0:
			finished.append(job)

	for job in finished:
		_finish_job(job)

	_try_start_next()


func _finish_job(job: Job) -> void:
	_active_jobs.erase(job)
	job.status = "completed"

	# Generate output
	if job.has_meta("output_generator"):
		var generator: Callable = job.get_meta("output_generator")
		if generator.is_valid():
			job.output = str(generator.call())

	_completed_jobs.append(job)
	job_completed.emit(job)
	if job.callback.is_valid():
		job.callback.call(job)


func get_active_jobs() -> Array[Job]:
	return _active_jobs.duplicate()


func get_pending_jobs() -> Array[Job]:
	return _pending_jobs.duplicate()


func get_all_jobs() -> Array[Job]:
	var all: Array[Job] = []
	all.append_array(_pending_jobs)
	all.append_array(_active_jobs)
	all.append_array(_completed_jobs)
	return all


func get_job_by_id(job_id: int) -> Job:
	for job in get_all_jobs():
		if job.id == job_id:
			return job
	return null


func get_active_count() -> int:
	return _active_jobs.size()


func get_pending_count() -> int:
	return _pending_jobs.size()
