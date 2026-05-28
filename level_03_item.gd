extends RigidBody3D

# 走廊宽度限制 x ∈ [-1.5, 1.5]，每个 item 还有自己的 z 巡游窗口
@export var home_z: float = 0.0
@export var z_half_range: float = 2.0
@export var min_retarget: float = 1.0
@export var max_retarget: float = 2.0
@export var min_speed: float = 2.0
@export var max_speed: float = 3.5

var _target_x: float = 0.0
var _target_z: float = 0.0
var _speed: float = 2.5
var _next_retarget_at: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_target_x = position.x
	_target_z = position.z
	_next_retarget_at = _now_seconds() + _rng.randf_range(0.1, 0.5)

func _now_seconds() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _physics_process(_delta: float) -> void:
	if freeze:
		return
	var t := _now_seconds()
	if t >= _next_retarget_at:
		_pick_new_target()
		_next_retarget_at = t + _rng.randf_range(min_retarget, max_retarget)
	var dx := _target_x - position.x
	var dz := _target_z - position.z
	var vx := signf(dx) * _speed if absf(dx) > 0.05 else 0.0
	# z 方向给小幅 jitter，不要让方块离 home_z 太远
	var z_pull := signf(_target_z - position.z) * 1.0 if absf(_target_z - position.z) > 0.05 else 0.0
	# 软限制 z 在 [home_z-z_half_range, home_z+z_half_range]
	if position.z < home_z - z_half_range:
		z_pull = 1.0
	elif position.z > home_z + z_half_range:
		z_pull = -1.0
	linear_velocity = Vector3(vx, linear_velocity.y, z_pull)

func _pick_new_target() -> void:
	_target_x = _rng.randf_range(-1.5, 1.5)
	_speed = _rng.randf_range(min_speed, max_speed)
	# 50% 几率小幅扰动 z
	if _rng.randf() < 0.5:
		var jitter := _rng.randf_range(-0.5, 0.5)
		_target_z = clampf(home_z + jitter, home_z - z_half_range, home_z + z_half_range)
	else:
		_target_z = position.z
