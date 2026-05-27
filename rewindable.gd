class_name Rewindable
extends RefCounted

static func capture(target: Node3D, time: float) -> StateFrame:
	var lv := Vector3.ZERO
	var av := Vector3.ZERO
	if target is RigidBody3D:
		lv = (target as RigidBody3D).linear_velocity
		av = (target as RigidBody3D).angular_velocity
	elif target is CharacterBody3D:
		lv = (target as CharacterBody3D).velocity
	return StateFrame.new(time, target.global_transform, lv, av)

static func apply(target: Node3D, frame: StateFrame) -> void:
	target.global_transform = frame.transform
	if target is RigidBody3D:
		(target as RigidBody3D).linear_velocity = frame.linear_v
		(target as RigidBody3D).angular_velocity = frame.angular_v
	elif target is CharacterBody3D:
		(target as CharacterBody3D).velocity = frame.linear_v

static func has_motion(target: Node3D, epsilon: float = 0.05) -> bool:
	if target is RigidBody3D:
		var rb := target as RigidBody3D
		return rb.linear_velocity.length() > epsilon or rb.angular_velocity.length() > epsilon
	elif target is CharacterBody3D:
		return (target as CharacterBody3D).velocity.length() > epsilon
	return false

static func set_frozen(target: Node3D, frozen: bool) -> void:
	if target is RigidBody3D:
		(target as RigidBody3D).freeze = frozen
	elif "time_controlled" in target:
		target.time_controlled = frozen
