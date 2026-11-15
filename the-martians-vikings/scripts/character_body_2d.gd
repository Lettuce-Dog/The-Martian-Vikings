extends CharacterBody2D

@export var speed := 200.0
@export var deadzone := 0.1
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var serial_x := 0.0  # Last horizontal value received from the Arduino
var serial_y := 0.0  # Last horizontal value received from the Arduino

func _ready() -> void:
	print("WIRK") # LEAVE IN
	add_to_group("player")

func _physics_process(_delta: float) -> void:
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
		

# Integration Stuff
signal finished(won: bool)

func end_minigame(won: bool):
	finished.emit(won)
	queue_free()
