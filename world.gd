extends Node3D

@onready var _actor: CharacterBody3D = $Actor
@onready var _pushbox: RigidBody3D = $PushBox
@onready var _camera: Camera3D = $Camera3D
@onready var _hud_joystick: Control = $HUD/Joystick
@onready var _hud_jump: Button = $HUD/JumpButton
@onready var _hud_exit: Button = $HUD/ExitButton
@onready var _hud_actor_rewind: Button = $HUD/ActorRewindButton
@onready var _hud_box_rewind: Button = $HUD/BoxRewindButton
@onready var _hud_actor_bar: ProgressBar = $HUD/ActorProgressBar
@onready var _hud_box_bar: ProgressBar = $HUD/BoxProgressBar
@onready var _actor_recorder: Node = $Actor/Recorder
@onready var _box_recorder: Node = $PushBox/Recorder
@onready var _actor_trail: MultiMeshInstance3D = $ActorTrail
@onready var _box_trail: MultiMeshInstance3D = $BoxTrail

func _ready() -> void:
	_actor.joystick = _hud_joystick
	_actor.camera = _camera
	_actor.recorder = _actor_recorder
	_actor_recorder.target = _actor
	_actor_recorder.trail = _actor_trail
	_actor_recorder.trail_color = Color(0.4, 0.7, 1.0, 1.0)
	_box_recorder.target = _pushbox
	_box_recorder.trail = _box_trail
	_box_recorder.trail_color = Color(1.0, 0.7, 0.4, 1.0)
	_camera.target = _actor
	_hud_jump.pressed.connect(_actor.queue_jump)
	_hud_exit.pressed.connect(_on_exit_pressed)
	_hud_actor_rewind.hold_started.connect(_actor_recorder.start_rewind)
	_hud_actor_rewind.hold_ended.connect(_actor_recorder.stop_rewind)
	_hud_box_rewind.hold_started.connect(_box_recorder.start_rewind)
	_hud_box_rewind.hold_ended.connect(_box_recorder.stop_rewind)

func _process(_delta: float) -> void:
	_hud_actor_bar.value = _actor_recorder.get_progress() * 100.0
	_hud_box_bar.value = _box_recorder.get_progress() * 100.0

func _on_exit_pressed() -> void:
	get_tree().quit()
	OS.kill(OS.get_process_id())
