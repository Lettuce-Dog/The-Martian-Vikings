extends Area2D
## Shows a selection box near this area while the player is inside it.

signal popup_opened
signal popup_closed
## Emitted when the player picks an option.
signal option_selected(index: int, text: String)

@export var title: String = "Notice"
@export_multiline var message: String = "Choose an option."
## One button is created per entry.
@export var options: PackedStringArray = ["Yes", "No"]
## Only bodies in this group trigger the pop-up.
@export var player_group: StringName = &"player"
## If true, the pop-up only ever appears once.
@export var one_shot: bool = false

var _used := false

@onready var _ui: Node2D = $Popup
@onready var _title_label: Label = %TitleLabel
@onready var _message_label: Label = %MessageLabel
@onready var _options_box: VBoxContainer = %Options


func _ready() -> void:
	_ui.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _ui.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	if _ui.visible or (one_shot and _used):
		return
	_used = true
	_title_label.text = title
	_message_label.text = message
	_build_options()
	_ui.show()
	if _options_box.get_child_count() > 0:
		(_options_box.get_child(0) as Button).grab_focus()
	popup_opened.emit()


func close() -> void:
	if not _ui.visible:
		return
	_ui.hide()
	popup_closed.emit()


func _build_options() -> void:
	for child in _options_box.get_children():
		_options_box.remove_child(child)
		child.queue_free()
	for i in options.size():
		var button := Button.new()
		button.text = options[i]
		button.pressed.connect(_on_option_pressed.bind(i))
		_options_box.add_child(button)


func _on_option_pressed(index: int) -> void:
	option_selected.emit(index, options[index])
	close()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(player_group):
		open()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(player_group):
		close()
