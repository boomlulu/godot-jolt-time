extends BaseLevel

# 第四关·平台稳定性测试关。
# 玩家出生在移动平台上方 → 自由落体 → 落到平台 → 平台 Lissajous 横移（前后左右）→ 玩家被原生带着走，纹丝不动。
# 无 timeline / rewind / 道具 / 计时——纯测 move_and_slide 原生移动平台 carry（AnimatableBody3D + sync_to_physics）。
#
# 数据化验证：每物理帧累计 carry 稳定性指标（漂移/着地率/平台行程/着地后 y 抖动/reset 次数）。
# 随时点 HUD"提交Bug" → 把累计指标复制到剪贴板，无需肉眼观察。判定标准见 _dump_state 末尾 expectation_hint。

const FALL_RESET_Y := -8.0

@onready var _camera: Camera3D = $Camera3D
@onready var _platform: AnimatableBody3D = $MovingPlatform
@onready var _hud_joystick: Control = $HUD/HUDBase/Joystick
@onready var _hud_timer: Label = $HUD/HUDBase/TimerLabel
@onready var _hud_tips: Label = $HUD/HUDBase/TipsLabel

var _actor_spawn: Vector3 = Vector3.ZERO

# --- carry 稳定性累计指标 ---
var _elapsed: float = 0.0
var _plat_home: Vector3 = Vector3.ZERO
var _plat_travel_max: float = 0.0
var _landed: bool = false
var _land_time: float = 0.0
var _ref_offset: Vector2 = Vector2.ZERO       # 着地瞬间 actor 相对 platform 的 xz 偏移（基准）
var _frames_since_land: int = 0
var _on_floor_frames: int = 0
var _drift_max: float = 0.0
var _drift_sum: float = 0.0
var _drift_samples: int = 0
var _actor_y_min: float = INF
var _actor_y_max: float = -INF
var _reset_count: int = 0

func _ready() -> void:
	super._ready()
	_actor.joystick = _hud_joystick
	_actor.camera = _camera
	_camera.target = _actor
	_actor_spawn = _actor.global_position
	_plat_home = _platform.global_position
	_hud_timer.visible = false  # 本关无计时
	_hud_tips.visible = false

func _physics_process(delta: float) -> void:
	_camera.tick_yaw(delta)
	_elapsed += delta
	_track_stability()
	# 掉出平台兜底：重置回出生点重新下落，方便反复测试
	if _actor.global_position.y < FALL_RESET_Y:
		_reset_count += 1
		_respawn_actor()

func _track_stability() -> void:
	_plat_travel_max = maxf(_plat_travel_max, _platform.global_position.distance_to(_plat_home))
	var on_floor: bool = _actor.is_on_floor()
	if not _landed:
		if not on_floor:
			return  # 还在下落，未着地
		_landed = true
		_land_time = _elapsed
		_ref_offset = _current_offset()
		_actor_y_min = _actor.global_position.y
		_actor_y_max = _actor.global_position.y
	_frames_since_land += 1
	if on_floor:
		_on_floor_frames += 1
		var drift: float = _current_offset().distance_to(_ref_offset)
		_drift_max = maxf(_drift_max, drift)
		_drift_sum += drift
		_drift_samples += 1
		_actor_y_min = minf(_actor_y_min, _actor.global_position.y)
		_actor_y_max = maxf(_actor_y_max, _actor.global_position.y)

func _current_offset() -> Vector2:
	return Vector2(
		_actor.global_position.x - _platform.global_position.x,
		_actor.global_position.z - _platform.global_position.z)

func _respawn_actor() -> void:
	_actor.velocity = Vector3.ZERO
	_actor.global_position = _actor_spawn

func _on_door_passed() -> void:
	get_tree().change_scene_to_file("res://world.tscn")

func _dump_state() -> Dictionary:
	var on_floor_pct: float = 0.0
	if _frames_since_land > 0:
		on_floor_pct = float(_on_floor_frames) / float(_frames_since_land) * 100.0
	var drift_mean: float = 0.0
	if _drift_samples > 0:
		drift_mean = _drift_sum / float(_drift_samples)
	var drift_now: float = _current_offset().distance_to(_ref_offset) if _landed else 0.0
	var y_band: float = (_actor_y_max - _actor_y_min) if _landed else 0.0
	return {
		"level": "04_platform",
		"elapsed_s": _elapsed,
		"landed": _landed,
		"land_time_s": _land_time,
		"reset_count": _reset_count,
		"carry_stability": {
			"drift_max_m": _drift_max,
			"drift_mean_m": drift_mean,
			"drift_now_m": drift_now,
			"on_floor_pct": on_floor_pct,
			"ref_offset_xz": _ref_offset,
			"actor_y_min": _actor_y_min if _landed else 0.0,
			"actor_y_max": _actor_y_max if _landed else 0.0,
			"actor_y_band_m": y_band,
		},
		"platform": {
			"pos": _platform.global_position,
			"home": _plat_home,
			"travel_max_from_home_m": _plat_travel_max,
		},
		"actor": {
			"pos": _actor.global_position,
			"vel": _actor.velocity,
			"on_floor": _actor.is_on_floor(),
			"rel_offset_xz_now": _current_offset(),
		},
		"expectation_hint": "PASS if: landed=true & reset_count=0 & drift_max_m<0.20 & on_floor_pct>=99 & travel_max_from_home_m>1.0 & actor_y_band_m<0.15",
	}
