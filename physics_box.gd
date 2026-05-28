extends RigidBody3D

# 物理推箱节点（参与活动判定的 RigidBody3D）
# has_activity 接口符合 §4 接口契约：linear/angular velocity 超阈值即视为有物理活动
func has_activity() -> bool:
	return linear_velocity.length() > Rewindable.MOTION_EPSILON \
		or angular_velocity.length() > Rewindable.MOTION_EPSILON
