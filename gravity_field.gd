class_name GravityField
extends Area3D

# 可控引力场。enter_tree 时自动注册到 GravityManager，exit_tree 时反注册。
# - gravity_vector: 方向 + 强度合一。默认 (0,-18,0) 与标准重力等价。
# - priority: 多 field 覆盖同点时，priority 最高者胜出。
# - falloff_radius:
#     <= 0  -> 全场域均匀引力
#     >  0  -> 球形 falloff：距离 0 满强度，距离 = falloff_radius 衰减为 0

@export var gravity_vector: Vector3 = Vector3(0, -18, 0)
@export var field_priority: int = 0
@export var falloff_radius: float = 0.0

func _enter_tree() -> void:
	GravityManager.register(self)

func _exit_tree() -> void:
	GravityManager.unregister(self)

# 给点 p 计算这个 field 的引力贡献（线性 falloff）
func get_gravity_at(p: Vector3) -> Vector3:
	if falloff_radius <= 0.0:
		return gravity_vector
	var dist: float = global_position.distance_to(p)
	if dist >= falloff_radius:
		return Vector3.ZERO
	var t: float = 1.0 - dist / falloff_radius
	return gravity_vector * t
