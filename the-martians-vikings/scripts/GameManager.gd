
extends Node

signal stats_changed

var sol: int = 1
var science_points: int = 0
var crew_health: int = 100
var radiation_dose: float = 0.0
var shelter_protection: int = 0

var shelter_repaired: bool = false
var research_completed: bool = false

const MAX_SOLS: int = 5
const SCIENCE_GOAL: int = 100


func add_science(amount: int) -> void:
	science_points += amount
	stats_changed.emit()


func complete_shelter_repair(score: int) -> void:
	shelter_protection = score
	shelter_repaired = true
	stats_changed.emit()


func conduct_research() -> void:
	if research_completed:
		return

	add_science(25)
	research_completed = true
	stats_changed.emit()


func advance_sol() -> void:
	# Simplified radiation simulation.
	var exposure: float = 5.0

	# Solar particle event on Sol 3.
	if sol == 3:
		exposure = 35.0

	# Shielding reduces exposure.
	var reduction: float = (
		float(shelter_protection) / 20.0
	)

	exposure *= (1.0 - reduction)

	radiation_dose += exposure

	# Fictional crew-health penalty for gameplay.
	crew_health -= int(exposure * 0.5)
	crew_health = maxi(crew_health, 0)

	sol += 1
	research_completed = false

	stats_changed.emit()


func is_mission_over() -> bool:
	return (
		crew_health <= 0
		or sol > MAX_SOLS
	)


func mission_success() -> bool:
	return (
		crew_health > 0
		and science_points >= SCIENCE_GOAL
		and sol > MAX_SOLS
	)
