extends Node3D

@export var TIMER_START: float = 10.0

const LEVELS := [
	{"name": "新手引导", "scene": "res://world.tscn"},
	{"name": "下一关", "scene": "res://level_02.tscn"},
]

const _TOUCH_BUTTON_SCRIPT := preload("res://touch_button.gd")

@onready var _actor: CharacterBody3D = $Actor
@onready var _pushbox: RigidBody3D = $PushBox
@onready var _camera: Camera3D = $Camera3D
@onready var _hud_joystick: Control = $HUD/Joystick
@onready var _hud_jump: Button = $HUD/JumpButton
@onready var _hud_exit: Button = $HUD/ExitButton
@onready var _hud_actor_rewind: Button = $HUD/ActorRewindButton
@onready var _hud_box_rewind: Button = $HUD/BoxRewindButton
@onready var _hud_timer: Label = $HUD/TimerLabel
@onready var _hud_dialog: AcceptDialog = $HUD/GameOverDialog
@onready var _hud_timeline: Control = $HUD/TimelineBar
@onready var _hud_gm_button: Button = $HUD/GMButton
@onready var _hud_gm_panel: Control = $HUD/GMPanel
@onready var _hud_gm_close: Button = $HUD/GMPanel/CenterBox/VBox/CloseButton
@onready var _hud_level_buttons: VBoxContainer = $HUD/GMPanel/CenterBox/VBox/LevelButtons
@onready var _actor_recorder: Node = $Actor/Recorder
@onready var _box_recorder: Node = $PushBox/Recorder
@onready var _door: Area3D = $Door
@onready var _actor_trail: MultiMeshInstance3D = $ActorTrail
@onready var _box_trail: MultiMeshInstance3D = $BoxTrail

var _timer: float = 0.0
var _game_over := false

func _ready() -> void:
	_timer = TIMER_START
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
	_door.body_entered.connect(_on_door_entered)
	_hud_dialog.confirmed.connect(_on_restart)
	_hud_gm_button.pressed.connect(_on_gm_open)
	_hud_gm_close.pressed.connect(_on_gm_close)
	_hud_timeline.total_duration = TIMER_START
	_hud_timeline.rewind_window = 3.0
	_hud_timeline.set_state(TIMER_START - _timer, false)
	_populate_levels()
	_update_timer_label()

func _process(delta: float) -> void:
	if _game_over:
		return
	var tick_dt := 0.0
	if _actor_recorder.is_actively_rewinding():
		_timer = minf(_timer + delta, TIMER_START)
		tick_dt = -delta
	elif _is_player_inputting():
		_timer -= delta
		if _timer <= 0.0:
			_timer = 0.0
			_trigger_game_over()
		tick_dt = delta
	if tick_dt != 0.0:
		_actor_recorder.tick_game_time(tick_dt)
		_box_recorder.tick_game_time(tick_dt)
	_update_timer_label()
	_hud_timeline.set_state(TIMER_START - _timer, _actor_recorder.is_rewinding)

func _is_player_inputting() -> bool:
	if _hud_joystick.value.length() > 0.0:
		return true
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D):
		return true
	if Input.is_key_pressed(KEY_SPACE):
		return true
	if _box_recorder.is_rewinding:
		return true
	return false

func _update_timer_label() -> void:
	var total_ms := int(_timer * 1000.0)
	var m := total_ms / 60000
	var s := (total_ms / 1000) % 60
	var ms := total_ms % 1000
	_hud_timer.text = "%02d:%02d:%03d" % [m, s, ms]

func _trigger_game_over() -> void:
	_game_over = true
	get_tree().paused = true
	_hud_dialog.popup_centered()

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	get_tree().quit()
	OS.kill(OS.get_process_id())

func _on_door_entered(body: Node3D) -> void:
	if body == _actor:
		get_tree().change_scene_to_file("res://level_02.tscn")

func _populate_levels() -> void:
	for level in LEVELS:
		var btn := Button.new()
		btn.set_script(_TOUCH_BUTTON_SCRIPT)
		btn.text = level.name
		btn.custom_minimum_size = Vector2(0, 60)
		btn.pressed.connect(_on_level_pressed.bind(level.scene))
		_hud_level_buttons.add_child(btn)

func _on_gm_open() -> void:
	_hud_gm_panel.visible = true

func _on_gm_close() -> void:
	_hud_gm_panel.visible = false

func _on_level_pressed(scene_path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
