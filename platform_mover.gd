extends AnimatableBody3D

# 移动平台：X/Z 双正弦（Lissajous）横移，覆盖"前后左右"。
# sync_to_physics=true → 站上去的 CharacterBody3D 经 move_and_slide 原生跟随（帧级稳，无手动 carry）。
# 同时加入 "platform" 组，与 level_03 搭乘判定约定一致。

@export var amplitude_x: float = 3.0
@export var amplitude_z: float = 3.0
@export var freq_x_hz: float = 0.18
@export var freq_z_hz: float = 0.13
@export var phase_z: float = 0.0  # 两轴同相 → 起步从 home 平滑漂出，覆盖"前后左右"
@export var start_delay: float = 0.8  # 起步前停在 home 的秒数：给玩家从高空落地，落稳后平台才动

var _home: Vector3 = Vector3.ZERO
var _t: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	_home = global_position
	add_to_group("platform")

func _physics_process(delta: float) -> void:
	_t += delta
	if _t < start_delay:
		return  # 停在 home，等玩家落稳
	var mt: float = _t - start_delay
	var dx: float = sin(mt * freq_x_hz * TAU) * amplitude_x
	var dz: float = sin(mt * freq_z_hz * TAU + phase_z) * amplitude_z
	global_position = Vector3(_home.x + dx, _home.y, _home.z + dz)
