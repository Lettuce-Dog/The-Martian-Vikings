
extends Node2D

# MARS STORM SHELTER REPAIR MINIGAME
# Godot 4.x

signal shelter_repaired(protection_score: int)

const MAX_REPAIRS: int = 6
const PANEL_RISKS: Array[int] = [3, 2, 3, 2, 1, 2, 3, 2, 3]
const MAX_SCORE: int = 16

var repaired_panels: Array[bool] = []
var panel_buttons: Array[Button] = []

var repairs_remaining: int = MAX_REPAIRS
var game_finished: bool = false

var status_label: Label
var score_label: Label
var confirm_button: Button


func _ready() -> void:
	# Start with all nine panels damaged.
	for i in range(9):
		repaired_panels.append(false)

	create_interface()
	update_interface()


func create_interface() -> void:
	# Create a CanvasLayer for the UI.
	var canvas := CanvasLayer.new()
	add_child(canvas)

	# Full-screen background.
	var background := ColorRect.new()
	background.color = Color("#192333")
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	canvas.add_child(background)

	# Main vertical layout.
	var main := VBoxContainer.new()
	main.position = Vector2(251, 25)
	main.custom_minimum_size = Vector2(650, 580)
	main.add_theme_constant_override("separation", 10)
	canvas.add_child(main)
	# Game title.
	var title := Label.new()
	title.text = "MARS STORM SHELTER REPAIR"
	title.add_theme_font_size_override("font_size", 28)
	main.add_child(title)

	# Instructions and status.
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	main.add_child(status_label)

	# Create a 3x3 grid.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(
		"h_separation", 10
	)
	grid.add_theme_constant_override(
		"v_separation", 10
	)
	main.add_child(grid)

	# Generate nine repairable panels.
	for i in range(9):
		var button := Button.new()
		button.custom_minimum_size = Vector2(190, 110)

		button.pressed.connect(
			_on_panel_pressed.bind(i)
		)

		grid.add_child(button)
		panel_buttons.append(button)

	# Protection score display.
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 20)
	main.add_child(score_label)

	# Confirm repairs button.
	confirm_button = Button.new()
	confirm_button.text = "CONFIRM REPAIRS"
	confirm_button.custom_minimum_size = Vector2(300, 55)
	confirm_button.pressed.connect(_on_confirm_pressed)
	main.add_child(confirm_button)

	# Restart button.
	var restart_button := Button.new()
	restart_button.text = "CLOSE"
	restart_button.custom_minimum_size = Vector2(150, 45)
	restart_button.pressed.connect(restart_game)
	main.add_child(restart_button)


func _on_panel_pressed(index: int) -> void:
	if game_finished:
		return

	# Undo an existing repair.
	if repaired_panels[index]:
		repaired_panels[index] = false
		repairs_remaining += 1

	# Repair a new panel if supplies remain.
	elif repairs_remaining > 0:
		repaired_panels[index] = true
		repairs_remaining -= 1

	update_interface()


func update_interface() -> void:
	# Show the current status.
	if not game_finished:
		status_label.text = (
			"Shielding panels remaining: %d"
			% repairs_remaining
		)

	# Update the protection score.
	var score := calculate_score()

	score_label.text = (
		"Protection score: %d / %d"
		% [score, MAX_SCORE]
	)

	# Update the appearance of every panel.
	for i in range(9):
		var button := panel_buttons[i]
		var risk := PANEL_RISKS[i]

		if repaired_panels[i]:
			button.text = (
				"PANEL %d\nREPAIRED"
				% (i + 1)
			)
			button.modulate = Color.GREEN

		else:
			var risk_name := "LOW"

			if risk == 3:
				risk_name = "HIGH"
			elif risk == 2:
				risk_name = "MEDIUM"

			button.text = (
				"PANEL %d\n%s RISK"
				% [i + 1, risk_name]
			)

			if risk == 3:
				button.modulate = Color.RED
			elif risk == 2:
				button.modulate = Color.ORANGE
			else:
				button.modulate = Color.GRAY

		# Prevent editing after confirmation.
		button.disabled = game_finished

	# Enable confirmation only when all
	# six repair panels have been allocated.
	confirm_button.disabled = (
		repairs_remaining != 0 or game_finished
	)


func calculate_score() -> int:
	var score := 0

	for i in range(9):
		if repaired_panels[i]:
			score += PANEL_RISKS[i]

	return score


func _on_confirm_pressed() -> void:
	if game_finished or repairs_remaining != 0:
		return

	game_finished = true

	var score := calculate_score()

	# Update the interface first.
	update_interface()

	# Then display the final mission result.
	if score >= 16:
		status_label.text = (
			"MISSION SUCCESS! Excellent shielding!"
		)

	elif score >= 13:
		status_label.text = (
			"MISSION COMPLETE! Good protection."
		)

	else:
		status_label.text = (
			"MISSION COMPLETE! Shielding could improve."
		)

	# Send the result to the main Mars game.
		GameManager.complete_shelter_repair(score)
		shelter_repaired.emit(score)

		get_tree().change_scene_to_file(
		"res://MissionControl.tscn"
		)


func restart_game() -> void:
	# Reset all panels.
	repaired_panels.clear()

	for i in range(9):
		repaired_panels.append(false)

	repairs_remaining = MAX_REPAIRS
	game_finished = false
	end_minigame(true)
	update_interface()

func end_minigame(won: bool):
	shelter_repaired.emit(won)
	queue_free()
