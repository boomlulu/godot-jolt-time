class_name BaseLevel
extends Node3D

const BugReport := preload("res://bug_report.gd")
const GameSettings := preload("res://game_settings.gd")

@onready var _gm_panel = $HUD/GMPanel
@onready var _hud_bug: Button = $HUD/BugReportButton
@onready var _hud_exit: Button = $HUD/ExitButton

func _ready() -> void:
	_gm_panel.set_levels(_get_levels())
	_gm_panel.level_chosen.connect(_on_level_pressed)
	_hud_bug.pressed.connect(_on_bug_report)
	_hud_exit.pressed.connect(_on_exit_pressed)

# 子类必须 override
func _get_levels() -> Array:
	return []

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
