extends Node2D

# Setup Serial
var serial: GdSerial
var port_name: String

# Arduino Joystick
var joystick_dir := Vector2.ZERO

# API Setup
const API_KEY := "zrWQHBbfmzBRMhmMHGtwBNrDLD9FtLB9pHNtJfrn"
@onready var http := HTTPRequest.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(http)
	var url := "https://api.nasa.gov/insight_weather/?api_key=%s&feedtype=json&ver=1.0" % API_KEY
	http.request(url)
	var response = await http.request_completed
	var response_code = response[1]
	var body = response[3]

	if response_code != 200:
		push_error("HTTP error: %s" % response_code)
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	for sol in data["sol_keys"]:
		var day = data[sol]
		if day.has("AT"):  # sensors sometimes have gaps, so check first
			print("Sol %s: high %.1f°C, low %.1f°C" % [sol, day["AT"]["mx"], day["AT"]["mn"]])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
