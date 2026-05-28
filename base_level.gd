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

# 处理 timeline state 流转的通用 helper。三关共用。
#   timeline:        要 tick 的 Timeline
#   delta:           物理 delta
#   input_active:    本帧活动检测结果
#   on_freeze:       Callable(freeze: bool)，level 决定怎么冻结自己的目标
#   on_advance_end:  Callable() —— ADVANCING 一帧推进后调一次（一般用来检 timeout）。
#                    传 func(): pass 表示什么都不做
#   waiting_ref:     Callable() -> bool 返回 _waiting_for_input；如果不需要 waiting 门控，
#                    传 func(): return false（IDLE 时 freeze=false）
#   clear_waiting:   Callable()，ADVANCING 进入时清掉 waiting flag。不需要传 func(): pass
func _tick_timeline(timeline: Timeline, delta: float, input_active: bool,
					on_freeze: Callable, on_advance_end: Callable,
					waiting_ref: Callable, clear_waiting: Callable) -> void:
	var state := timeline.get_game_state(input_active)
	match state:
		Timeline.State.GAME_OVER, Timeline.State.DRAGGING, Timeline.State.LOCKED:
			on_freeze.call(true)
			timeline.disable_recording()
		Timeline.State.REWINDING:
			on_freeze.call(true)
			timeline.disable_recording()
			timeline.step_backward(delta)
		Timeline.State.ADVANCING:
			clear_waiting.call()
			on_freeze.call(false)
			timeline.advance(delta)
			on_advance_end.call()
		Timeline.State.IDLE:
			on_freeze.call(waiting_ref.call())
			timeline.disable_recording()
