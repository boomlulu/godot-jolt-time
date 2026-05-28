extends Control

signal level_chosen(scene_path: String)

const _TOUCH_BUTTON_SCRIPT := preload("res://touch_button.gd")

@export var levels: Array = []

@onready var _gm_button: Button = $GMButton
@onready var _overlay: Control = $PanelOverlay
@onready var _close_button: Button = $PanelOverlay/CenterBox/VBox/CloseButton
@onready var _level_buttons: VBoxContainer = $PanelOverlay/CenterBox/VBox/LevelButtons

func _ready() -> void:
	_gm_button.pressed.connect(_on_open)
	_close_button.pressed.connect(_on_close)
	_overlay.visible = false

func set_levels(arr: Array) -> void:
	levels = arr
	if is_node_ready():
		_populate()

func _populate() -> void:
	for child in _level_buttons.get_children():
		child.queue_free()
	for level in levels:
		var btn := Button.new()
		btn.set_script(_TOUCH_BUTTON_SCRIPT)
		btn.text = level.name
		btn.custom_minimum_size = Vector2(0, 60)
		btn.pressed.connect(_on_level_pressed.bind(level.scene))
		_level_buttons.add_child(btn)

func _on_open() -> void:
	_overlay.visible = true

func _on_close() -> void:
	_overlay.visible = false

func _on_level_pressed(scene_path: String) -> void:
	level_chosen.emit(scene_path)
