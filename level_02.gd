extends Node3D

@onready var _back: Button = $HUD/BackButton

func _ready() -> void:
	_back.pressed.connect(_on_back)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://world.tscn")
