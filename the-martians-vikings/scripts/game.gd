extends Node2D

# Setup NASA API
const API_KEY := "zrWQHBbfmzBRMhmMHGtwBNrDLD9FtLB9pHNtJfrn"
@onready var http := HTTPRequest.new()
var wind_speeds: Dictionary
var temperatures: Dictionary

# Pre-load minigames
const repair_game = preload("res://scenes/repair_game.tscn")
const panel_game = preload("res://scenes/solar_panel_game.tscn")

# Serial Stuff
var serial: GdSerial
var port_name := ""
var serial_x := 0.0  # Last horizontal value received from the Arduino
var serial_y := 0.0

func start_repair_minigame():
	var mg = repair_game.instantiate()
	mg.shelter_repaired.connect(_on_minigame_finished)
	get_tree().root.add_child(mg)
	# freeze and hide the level
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	
#func start_panel_minigame():
	#var mg = panel_game.instantiate()
	#mg.cleaned.connect(_on_minigame_finished)
	#get_tree().root.add_child(mg)
	## freeze and hide the level
	#process_mode = Node.PROCESS_MODE_DISABLED
	#visible = false
func start_panel_minigame():
	var mg = panel_game.instantiate()
	mg.game = self
	mg.cleaned.connect(_on_minigame_finished)
	get_tree().root.add_child(mg)
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
	print("WIRK") # LEAVE IN
	serial = GdSerial.new()
	var ports = serial.list_ports()
	print("Available ports: ", ports)

	for port in ports:
		var device: String = ports[port]["device_name"]
		if device.contains("Arduino"):
			port_name = ports[port]["port_name"]
			print("Arduino Port Found: ", port_name)
			break

	if port_name == "":
		push_warning("No Arduino found. Using keyboard input only.")
		return

	serial.set_port(port_name)
	serial.set_baud_rate(9600)
	serial.open()

func _read_serial() -> void:
	if serial == null or not serial.is_open():
		return
	var line := serial.readline().strip_edges()
	if line == "":
		return  # Keep the last value if nothing new arrived
	var parts := line.split(",")
	if parts.size() >= 2 and parts[0].is_valid_float():
		serial_x = parts[0].to_float()
		serial_y = parts[1].to_float()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_read_serial()
	
	$Player/CharacterBody2D.serial_x = serial_x
	if has_node("solar_panel_game"):
		$solar_panel_name.dir2 = Vector2(serial_x,serial_y)

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
