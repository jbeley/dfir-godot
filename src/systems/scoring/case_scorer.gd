class_name CaseScorer
extends RefCounted
## Scores a completed investigation based on IOC accuracy, ATT&CK mapping,
## timeline completeness, and timeliness.

class ScoreResult:
	var total_score: float = 0.0  # 0-100
	var ioc_score: float = 0.0
	var technique_score: float = 0.0
	var timeline_score: float = 0.0
	var timeliness_score: float = 0.0
	var reputation_earned: float = 0.0
	var grade: String = "F"
	var feedback: PackedStringArray = []


func score_case(case_data: CaseData) -> ScoreResult:
	var result := ScoreResult.new()

	result.ioc_score = _score_iocs(case_data, result.feedback)
	result.technique_score = _score_techniques(case_data, result.feedback)
	result.timeline_score = _score_timeline(case_data, result.feedback)
	result.timeliness_score = _score_timeliness(case_data, result.feedback)

	# Weighted total
	result.total_score = (
		result.ioc_score * 0.40 +
		result.technique_score * 0.25 +
		result.timeline_score * 0.15 +
		result.timeliness_score * 0.20
	)

	# Grade
	if result.total_score >= 95:
		result.grade = "S"
	elif result.total_score >= 85:
		result.grade = "A"
	elif result.total_score >= 70:
		result.grade = "B"
	elif result.total_score >= 55:
		result.grade = "C"
	elif result.total_score >= 40:
		result.grade = "D"
	else:
		result.grade = "F"

	# Reputation earned scales with grade
	var grade_multiplier := {"S": 1.5, "A": 1.2, "B": 1.0, "C": 0.7, "D": 0.4, "F": 0.1}
	result.reputation_earned = case_data.reputation_reward * grade_multiplier.get(result.grade, 0.5)

	return result


func _score_iocs(case_data: CaseData, feedback: PackedStringArray) -> float:
	var correct := case_data.correct_iocs
	var discovered := case_data.discovered_iocs

	if correct.is_empty():
		feedback.append("No IOCs expected for this case.")
		return 100.0

	if discovered.is_empty():
		feedback.append("No IOCs submitted! You missed all indicators.")
		return 0.0

	# Count matches
	var correct_values: Array[String] = []
	for ioc: IOCData in correct:
		correct_values.append(ioc.value)

	var true_positives := 0
	var false_positives := 0
	var discovered_values: Array[String] = []

	for ioc: IOCData in discovered:
		discovered_values.append(ioc.value)
		if ioc.value in correct_values:
			true_positives += 1
		else:
			false_positives += 1

	var missed := 0
	for val: String in correct_values:
		if val not in discovered_values:
			missed += 1

	# Precision and recall
	var precision := float(true_positives) / float(true_positives + false_positives) if (true_positives + false_positives) > 0 else 0.0
	var recall := float(true_positives) / float(correct.size()) if correct.size() > 0 else 0.0

	# F1-like score
	var score := 0.0
	if precision + recall > 0:
		score = 2.0 * precision * recall / (precision + recall) * 100.0

	# Feedback
	feedback.append("IOCs: %d/%d found (precision: %.0f%%, recall: %.0f%%)" % [
		true_positives, correct.size(), precision * 100, recall * 100
	])
	if missed > 0:
		feedback.append("Missed %d IOC(s)" % missed)
	if false_positives > 0:
		feedback.append("%d false positive IOC(s) submitted" % false_positives)

	return score


func _score_techniques(case_data: CaseData, feedback: PackedStringArray) -> float:
	var expected := case_data.attack_technique_ids
	var mapped := case_data.mapped_techniques

	if expected.is_empty():
		return 100.0

	if mapped.is_empty():
		feedback.append("No ATT&CK techniques mapped.")
		return 0.0

	var hits := 0
	for tech_id: String in expected:
		if tech_id in mapped:
			hits += 1

	var score := float(hits) / float(expected.size()) * 100.0

	feedback.append("ATT&CK: %d/%d techniques correctly mapped" % [hits, expected.size()])
	return score


func _score_timeline(case_data: CaseData, feedback: PackedStringArray) -> float:
	var events := case_data.timeline_entries

	if events.is_empty():
		feedback.append("No timeline events created.")
		return 0.0

	# Score based on number of events (more = better, diminishing returns)
	var count := events.size()
	var score := minf(count * 15.0, 100.0)  # 7+ events = 100%

	feedback.append("Timeline: %d events recorded" % count)
	return score


func _score_timeliness(case_data: CaseData, feedback: PackedStringArray) -> float:
	var remaining := case_data.get_hours_remaining()
	var total := case_data.deadline_hours

	if remaining <= 0:
		feedback.append("Case submitted PAST DEADLINE!")
		return 0.0

	var time_used_ratio := 1.0 - (remaining / total)

	# Bonus for finishing early
	if time_used_ratio < 0.5:
		feedback.append("Completed well ahead of deadline!")
		return 100.0
	elif time_used_ratio < 0.75:
		feedback.append("Completed with time to spare.")
		return 85.0
	elif time_used_ratio < 0.95:
		feedback.append("Cutting it close on the deadline.")
		return 65.0
	else:
		feedback.append("Just barely made the deadline.")
		return 40.0
