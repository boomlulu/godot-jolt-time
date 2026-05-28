class_name CarryRelation
extends RefCounted

# 单个 rider 跟随 platform 移动的关系。
# 用法：
#   var c := CarryRelation.new(actor, platform)
#   每物理帧调 c.update() —— 计算 platform 自上次以来的位移 dx，把 rider 沿同样 dx 平移
#   不需要时 c = null 即可
#
# 设计动机：level_03 carry 现在硬编码 actor + 单一 platform 的特殊逻辑。
# 当出现多个移动平台 / 多个 rider / box 被平台搬运时直接复用本类。

var rider: Node3D = null
var platform: Node3D = null
var _last_platform_pos: Vector3 = Vector3.ZERO

func _init(r: Node3D, p: Node3D) -> void:
	rider = r
	platform = p
	if platform != null:
		_last_platform_pos = platform.global_position

# 计算 platform 自上次 update 以来的位移，应用到 rider
func update() -> void:
	if rider == null or platform == null:
		return
	var current: Vector3 = platform.global_position
	var dx: Vector3 = current - _last_platform_pos
	if dx.length_squared() > 0.0:
		rider.global_position += dx
	_last_platform_pos = current

# 重新锚定到当前 platform 位置（不再追溯之前的 dx）
func rebase() -> void:
	if platform != null:
		_last_platform_pos = platform.global_position
