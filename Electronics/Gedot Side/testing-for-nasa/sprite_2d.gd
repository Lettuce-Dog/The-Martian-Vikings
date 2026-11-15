extends Sprite2D

var serial: GdSerial

var dir := Vector2.ZERO
var port_name := ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	serial = GdSerial.new()
	var ports = serial.list_ports()
	print("Available ports: ", ports)
	
	# Locates the arduino port automatically.
	for port in ports:
		var name = ports[port]["device_name"]
		var name_cutoff = name.rfind(" ")
		if name_cutoff != -1:
			name = name.substr(0, name_cutoff)
		if name == "Arduino LLC (www.arduino.cc) Arduino Uno":
			port_name = ports[port]["port_name"]
			print("Arduino Port Found!")
	
	# Begins serial connection.
	serial.set_port(port_name)  # Adjust for your system
	serial.set_baud_rate(9600)
	serial.open()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if serial == null or not serial.is_open():
		return
	
	var line := serial.readline().strip_edges()
	var parts := line.split(",")
	
	if parts.size() >= 2:
		dir = Vector2(parts[0].to_float(),-1*parts[1].to_float())
		
	position += dir * 100 * delta
	
	print(parts)

	#if parts.size() == 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
		#dir = Vector2(parts[0].to_float(), parts[1].to_float())
	#
	#position += delta * 100.0 * dir
	
	
	
	
