extends Node

# 全局引力管理器（autoload singleton）
# 负责注册 GravityField，按点查询当前生效引力。
# 无任何 field 覆盖某点时返回 DEFAULT_GRAVITY。

const DEFAULT_GRAVITY := Vector3(0, -18, 0)

var _fields: Array = []  # GravityField 列表

func register(f) -> void:
	if not _fields.has(f):
		_fields.append(f)

func unregister(f) -> void:
	_fields.erase(f)

# 给世界中某点 p 计算最终生效的引力
# 规则：所有覆盖该点的 field 中，priority 最高的胜出；都未覆盖则返回 DEFAULT_GRAVITY
func resolve_gravity(p: Vector3) -> Vector3:
	var best = null
	var best_pri: int = -2147483648
	for f in _fields:
		if not is_instance_valid(f):
			continue
		if not _point_in_area(p, f):
			continue
		if f.field_priority > best_pri:
			best_pri = f.field_priority
			best = f
	if best == null:
		return DEFAULT_GRAVITY
	return best.get_gravity_at(p)

# 简化版作用域判定：
# - falloff_radius <= 0 表示全场域 field（始终覆盖）
# - falloff_radius > 0  表示球形作用域，距离中心 <= falloff_radius 才覆盖
func _point_in_area(p: Vector3, f) -> bool:
	if f.falloff_radius <= 0.0:
		return true
	return f.global_position.distance_to(p) <= f.falloff_radius
