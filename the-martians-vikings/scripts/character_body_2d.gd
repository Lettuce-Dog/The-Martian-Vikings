extends CharacterBody2D

@export var speed := 200.0
@export var deadzone := 0.1
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var serial: GdSerial
var port_name := ""
var serial_x := 0.0  # Last horizontal value received from the Arduino

func _ready() -> void:
	print("WIRK") # LEAVE IN
	add_to_group("player")
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
	if parts.size() >= 1 and parts[0].is_valid_float():
		serial_x = parts[0].to_float()

func _physics_process(_delta: float) -> void:
	_read_serial()

	# Keyboard takes priority; the Arduino is used when no key is pressed.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction == 0.0 and absf(serial_x) > deadzone:
		direction = clampf(serial_x, -1.0, 1.0)

	velocity.x = direction * speed
	move_and_slide()

	if direction != 0:
		sprite.flip_h = direction < 0
		sprite.play("walk")
	else:
		sprite.play("idle")
