extends Node

func run_all(runner: Node) -> void:
	_test_b_kinematic_freeze_has_no_motion(runner)
	_test_b_normal_rigid_has_motion(runner)
	_test_b_character_body_motion(runner)

# B: KINEMATIC freeze RigidBody3D 即使 linear_velocity 非零也不算 motion
func _test_b_kinematic_freeze_has_no_motion(runner: Node) -> void:
	var rb := RigidBody3D.new()
	rb.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	rb.freeze = true
	rb.linear_velocity = Vector3(5, 0, 0)
	runner.add_child(rb)
	var ok := not Rewindable.has_motion(rb)
	rb.queue_free()
	runner._check(ok, "B1 KINEMATIC freeze has_motion=false")

# B: 普通 RigidBody3D 带 velocity 应该报 motion
func _test_b_normal_rigid_has_motion(runner: Node) -> void:
	var rb := RigidBody3D.new()
	rb.linear_velocity = Vector3(5, 0, 0)
	runner.add_child(rb)
	var ok := Rewindable.has_motion(rb)
	rb.queue_free()
	runner._check(ok, "B2 non-frozen rigid has_motion=true")

# CharacterBody3D 行为不变
func _test_b_character_body_motion(runner: Node) -> void:
	var cb := CharacterBody3D.new()
	cb.velocity = Vector3(5, 0, 0)
	runner.add_child(cb)
	var ok := Rewindable.has_motion(cb)
	cb.queue_free()
	runner._check(ok, "B3 CharacterBody motion=true")
