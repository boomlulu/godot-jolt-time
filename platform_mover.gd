extends AnimatableBody3D

# 移动平台：X/Z 双正弦（Lissajous）横移，覆盖"前后左右"。
# sync_to_physics=true → 站上去的 CharacterBody3D 经 move_and_slide 原生跟随（帧级稳，无手动 carry）。
# 同时加入 "platform" 组，与 level_03 搭乘判定约定一致。
#
# 时间源：
#   timeline==null（第四关）：内部 _t 自由累计，平台自走。
#   timeline 已挂（第五关）：位置 = pos_at_time(timeline.current_time) 纯时间函数
#   → 时间轴前进/回退/拖动/冻结天然驱动平台，平台本身无需录制。

@export var amplitude_x: float = 3.0
@export var amplitude_z: float = 3.0
@export var freq_x_hz: float = 0.18
@export var freq_z_hz: float = 0.13
@export var phase_z: float = 0.0  # 两轴同相 → 起步从 home 平滑漂出，覆盖"前后左右"
@export var start_delay: float = 0.8  # 起步前停在 home 的秒数：给玩家从高空落地，落稳后平台才动

var timeline: Timeline = null  # 挂上则改由其 current_time 驱动（第五关）
var _home: Vector3 = Vector3.ZERO
var _t: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	_home = global_position
	add_to_group("platform")

func _physics_process(delta: float) -> void:
	var t: float
	if timeline != null:
		t = timeline.current_time
	else:
		_t += delta
		t = _t
	global_position = pos_at_time(t)

# 给定时间 t 返回平台应处位置（纯时间函数，供 _physics_process 与外部校验复用）
func pos_at_time(t: float) -> Vector3:
	var mt: float = t - start_delay
	if mt < 0.0:
		return _home  # 起步缓冲：停在 home
	var dx: float = sin(mt * freq_x_hz * TAU) * amplitude_x
	var dz: float = sin(mt * freq_z_hz * TAU + phase_z) * amplitude_z
	return Vector3(_home.x + dx, _home.y, _home.z + dz)
