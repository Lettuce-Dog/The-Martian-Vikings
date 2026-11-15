extends Node2D

# Setup NASA API
const API_KEY := "zrWQHBbfmzBRMhmMHGtwBNrDLD9FtLB9pHNtJfrn"
@onready var http := HTTPRequest.new()
var wind_speeds: Dictionary
var temperatures: Dictionary

# Pre-load minigames
const repair_game = preload("res://scenes/repair_game.tscn")
const panel_game = preload("res://scenes/solar_panel_game.tscn")

func start_repair_minigame():
	var mg = repair_game.instantiate()
	mg.shelter_repaired.connect(_on_minigame_finished)
	get_tree().root.add_child(mg)
	# freeze and hide the level
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	
func start_panel_minigame():
	var mg = panel_game.instantiate()
	mg.cleaned.connect(_on_minigame_finished)
	get_tree().root.add_child(mg)
	# freeze and hide the level
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false

func _on_minigame_finished(won: bool):
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	if won:
		print("Player won the minigame!")

func _on_repair_selected(index: int, text: String) -> void:
	match index:
		0:
			print("First option chosen")
			start_repair_minigame()
		1:
			print("Second option chosen")
			# e.g. nothing happens

func _on_panel_selected(index: int, text: String) -> void:
	match index:
		0:
			print("First option chosen")
			start_panel_minigame()
		1:
			print("Second option chosen")
			# e.g. nothing happens

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var data = await get_API_data() # retrieve data from NASA API
	var sol = data["sol_keys"][0] # select a day to retrieve data
	if data[sol].has("HWS"):
		wind_speeds = data[sol]["HWS"] # save wind data from the selected day
	if data[sol].has("AT"):
		temperatures = data[sol]["AT"] # save temperature data from the selected day
	print(wind_speeds)
	print(temperatures)
	
	$PopupArea.option_selected.connect(_on_repair_selected)
	$PopupArea2.option_selected.connect(_on_panel_selected)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_API_data() -> Dictionary:
	add_child(http)
	var url := "https://api.nasa.gov/insight_weather/?api_key=%s&feedtype=json&ver=1.0" % API_KEY
	http.request(url)
	var response = await http.request_completed
	var response_code = response[1]
	var body = response[3]
	
	if response_code != 200:
		push_error("HTTP error: %s" % response_code)
		return {}
	var data = JSON.parse_string(body.get_string_from_utf8())
	return data
