extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var start_point: Marker2D
@export var landing_point: Marker2D
@export var takeoff_point: Marker2D

@export var descent_time: float = 5.0
@export var landed_pause: float = 3.0
@export var takeoff_time: float = 3.0

func _ready() -> void:
	if start_point == null or landing_point == null or takeoff_point == null:
		push_error("Assign StartPoint, LandingPoint, and TakeoffPoint in the Inspector.")
		return

	global_position = start_point.global_position

	# Descend while playing the takeoff animation.
	sprite.play("takeoff")
	var landing_tween := create_tween()
	landing_tween.tween_property(
		self, "global_position", landing_point.global_position, descent_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await landing_tween.finished

	# Play the landing animation, then hold its last frame during the pause.
	sprite.play("landing")
	await sprite.animation_finished
	await get_tree().create_timer(landed_pause).timeout

	# Play takeoff again while rising off-screen.
	sprite.play("takeoff")
	var takeoff_tween := create_tween()
	takeoff_tween.tween_property(
		self, "global_position", takeoff_point.global_position, takeoff_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
