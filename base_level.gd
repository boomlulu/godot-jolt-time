class_name BaseLevel
extends Node3D

const BugReport := preload("res://bug_report.gd")
const GameSettings := preload("res://game_settings.gd")
const LevelsRegistry := preload("res://levels_registry.gd")

@onready var _gm_panel = $HUD/GMPanel
@onready var _hud_bug: Button = $HUD/BugReportButton
@onready var _hud_exit: Button = $HUD/ExitButton
@onready var _actor: CharacterBody3D = $Actor
@onready var _door: Area3D = $Door

var _door_triggered: bool = false

func _ready() -> void:
	_gm_panel.set_levels(_get_levels())
	_gm_panel.level_chosen.connect(_on_level_pressed)
	_hud_bug.pressed.connect(_on_bug_report)
	_hud_exit.pressed.connect(_on_exit_pressed)
	_door.body_entered.connect(_handle_door_body_entered)

# 默认所有关卡 LEVELS 共用；子类有特殊需求可 override
func _get_levels() -> Array:
	return LevelsRegistry.ALL

# 子类必须 override
func _dump_state() -> Dictionary:
	return {}

# 共享 handler
func _on_level_pressed(scene_path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)

func _on_exit_pressed() -> void:
	get_tree().quit()
	OS.kill(OS.get_process_id())

func _on_bug_report() -> void:
	await BugReport.copy_dict(_hud_bug, self, _dump_state())

# 共享辅助
func _state_name(s: int) -> String:
	match s:
		Timeline.State.IDLE: return "IDLE"
		Timeline.State.ADVANCING: return "ADVANCING"
		Timeline.State.REWINDING: return "REWINDING"
		Timeline.State.DRAGGING: return "DRAGGING"
		Timeline.State.LOCKED: return "LOCKED"
		Timeline.State.GAME_OVER: return "GAME_OVER"
	return "?"

# Door 模板方法：三关共用进门流程
func _handle_door_body_entered(body: Node3D) -> void:
	if _door_triggered:
		return
	if body != _actor:
		return
	if not _can_pass_door():
		_on_door_blocked()
		return
	_door_triggered = true
	_on_door_passed()

# 子类钩子（可选 override）
func _can_pass_door() -> bool:
	return true

func _on_door_blocked() -> void:
	pass

func _on_door_passed() -> void:
	pass

# 重启共用
func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
