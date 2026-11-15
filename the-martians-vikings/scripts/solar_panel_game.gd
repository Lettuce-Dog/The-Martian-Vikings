extends Node2D
## Solar panel cleaning minigame (Godot 4.x)
## Move the cursor with the joystick (left stick / D-pad / arrow keys).
## Just hovering over the dust cleans it off.
##
## SETUP: attach this script to an empty Node2D, then drag your clean
## solar panel image into the "Panel Texture" slot in the Inspector.

signal cleaned  # emitted when the panel is clean enough (hook up your game logic here)

@export var panel_texture: Texture2D
@export var cursor_speed: float = 450.0          # screen pixels per second
@export var brush_radius: float = 14.0           # in dust-image pixels
@export var dust_resolution := Vector2i(256, 256) # lower = faster, chunkier dust
@export_range(0.5, 1.0) var win_threshold: float = 0.97
@export var dust_color := Color(0.55, 0.45, 0.30)

var panel_sprite: Sprite2D
var dust_sprite: Sprite2D
var cursor: Node2D
var particles: CPUParticles2D
var label: Label

var dust_image: Image
var dust_texture: ImageTexture
var total_pixels: int
var dusty_pixels: int
var last_pixel := Vector2(-1, -1)
var finished := false

var dir2 := Vector2.ZERO
var game: Node  # set by game.gd before add_child

func _ready() -> void:
	_build_scene()
	_reset_dust()


func _build_scene() -> void:
	var center := get_viewport_rect().size / 2.0

	# 1) Clean solar panel (your image)
	panel_sprite = Sprite2D.new()
	panel_sprite.texture = panel_texture
	panel_sprite.position = center
	add_child(panel_sprite)

	# 2) Dust layer sits on top, same size as the panel
	dust_sprite = Sprite2D.new()
	dust_sprite.position = center
	add_child(dust_sprite)
	if panel_texture:
		var panel_size := panel_texture.get_size()
		dust_sprite.scale = panel_size / Vector2(dust_resolution)

	# 3) Dust puff particles that appear while you're cleaning
	particles = CPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 0.6
	particles.emitting = false
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, 60)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = dust_color
	var fade := Gradient.new()
	fade.set_color(0, Color(dust_color, 0.9))
	fade.set_color(1, Color(dust_color, 0.0))
	particles.color_ramp = fade
	add_child(particles)

	# 4) Cursor (a simple ring)
	cursor = Node2D.new()
	cursor.position = center
	cursor.draw.connect(func():
		cursor.draw_arc(Vector2.ZERO, brush_radius * dust_sprite.scale.x, 0, TAU, 32, Color.WHITE, 2.0)
	)
	add_child(cursor)

	# 5) Progress label
	var layer := CanvasLayer.new()
	add_child(layer)
	label = Label.new()
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 28)
	layer.add_child(label)


## Creates a fresh layer of noisy dust covering the whole panel.
func _reset_dust() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.04

	dust_image = Image.create(dust_resolution.x, dust_resolution.y, false, Image.FORMAT_RGBA8)
	for y in dust_resolution.y:
		for x in dust_resolution.x:
			var n := noise.get_noise_2d(x, y)               # -1 .. 1
			var alpha := clampf(0.6 + n * 0.5, 0.3, 0.9)    # patchy dust
			dust_image.set_pixel(x, y, Color(dust_color, alpha))

	dust_texture = ImageTexture.create_from_image(dust_image)
	dust_sprite.texture = dust_texture

	total_pixels = dust_resolution.x * dust_resolution.y
	dusty_pixels = total_pixels
	last_pixel = Vector2(-1, -1)
	finished = false
	cursor.position = get_viewport_rect().size / 2.0
	_update_label()


func _process(delta: float) -> void:
	if finished:
		if Input.is_action_just_pressed("ui_accept"):
			_reset_dust()
		return

# in _process, replacing line 121:
	if game:
		game._read_serial()
		dir2 = Vector2(game.serial_x, -1*game.serial_y)

	# Joystick input (ui_* actions are mapped to the left stick + D-pad by default)
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	cursor.position += dir * cursor_speed * delta
	cursor.position += dir2 * cursor_speed * delta

	# Keep the cursor inside the panel
	var half := panel_texture.get_size() / 2.0 if panel_texture else Vector2(200, 200)
	var c := panel_sprite.position
	cursor.position = cursor.position.clamp(c - half, c + half)

	# Convert cursor position to a pixel position in the dust image
	var pixel := dust_sprite.to_local(cursor.position) + Vector2(dust_resolution) / 2.0
	if last_pixel.x < 0:
		last_pixel = pixel

	var moving := (dir + dir2).length() > 0.1
	particles.position = cursor.position
	particles.emitting = moving and dusty_pixels > 0

	if moving:
		_clean_line(last_pixel, pixel)
		dust_texture.update(dust_image)
		_update_label()
	last_pixel = pixel

	if float(total_pixels - dusty_pixels) / total_pixels >= win_threshold:
		_finish()


## Erase dust along the path from a to b, so fast movement leaves no gaps.
func _clean_line(a: Vector2, b: Vector2) -> void:
	var dist := a.distance_to(b)
	var steps := maxi(1, int(dist / (brush_radius * 0.5)))
	for i in range(steps + 1):
		_clean_circle(a.lerp(b, float(i) / steps))


func _clean_circle(center: Vector2) -> void:
	var r := brush_radius
	var x0 := maxi(0, int(center.x - r))
	var x1 := mini(dust_resolution.x - 1, int(center.x + r))
	var y0 := maxi(0, int(center.y - r))
	var y1 := mini(dust_resolution.y - 1, int(center.y + r))

	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var d := Vector2(x, y).distance_to(center)
			if d > r:
				continue
			var px := dust_image.get_pixel(x, y)
			if px.a <= 0.0:
				continue
			# Fully clean in the middle, softer fade at the edge
			var strength := clampf((r - d) / (r * 0.4), 0.0, 1.0)
			px.a = maxf(0.0, px.a - strength)
			dust_image.set_pixel(x, y, px)
			if px.a <= 0.0:
				dusty_pixels -= 1


func _update_label() -> void:
	var pct := int(100.0 * (total_pixels - dusty_pixels) / total_pixels)
	label.text = "Clean: %d%%" % pct


func _finish() -> void:
	finished = true
	particles.emitting = false
	dust_image.fill(Color(0, 0, 0, 0))
	dust_texture.update(dust_image)
	label.text = "Panel clean! Press Enter / A to play again"
	end_minigame(finished)
	
func end_minigame(won: bool):
	print("ending minigame")   # check that this shows up in Output
	cleaned.emit(won)
	queue_free()
