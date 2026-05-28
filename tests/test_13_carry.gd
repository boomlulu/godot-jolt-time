extends Node

# CarryRelation 抽象测试

const CarryRelationCls := preload("res://carry_relation.gd")

func run_all(runner: Node) -> void:
	_test_13_carry_xy_translation(runner)
	_test_13_carry_3d_translation(runner)
	_test_13_carry_no_op_when_stationary(runner)
	_test_13_carry_rebase(runner)
	_test_13_carry_null_safe(runner)

func _test_13_carry_xy_translation(runner: Node) -> void:
	var rider := Node3D.new()
	var platform := Node3D.new()
	rider.global_position = Vector3.ZERO
	platform.global_position = Vector3.ZERO
	runner.add_child(rider)
	runner.add_child(platform)
	var c = CarryRelationCls.new(rider, platform)
	platform.global_position = Vector3(2, 0, 0)
	c.update()
	var ok: bool = absf(rider.global_position.x - 2.0) < 0.001
	rider.queue_free()
	platform.queue_free()
	runner._check(ok, "13.1 carry: platform +2 x -> rider +2 x")

func _test_13_carry_3d_translation(runner: Node) -> void:
	var rider := Node3D.new()
	var platform := Node3D.new()
	runner.add_child(rider)
	runner.add_child(platform)
	rider.global_position = Vector3(10, 5, -3)
	platform.global_position = Vector3.ZERO
	var c = CarryRelationCls.new(rider, platform)
	platform.global_position = Vector3(1, 2, -1)
	c.update()
	var expected := Vector3(11, 7, -4)
	var ok: bool = rider.global_position.distance_to(expected) < 0.001
	rider.queue_free()
	platform.queue_free()
	runner._check(ok, "13.2 carry: dx=(1,2,-1) -> rider moves by same vector")

func _test_13_carry_no_op_when_stationary(runner: Node) -> void:
	var rider := Node3D.new()
	var platform := Node3D.new()
	runner.add_child(rider)
	runner.add_child(platform)
	rider.global_position = Vector3(5, 0, 0)
	platform.global_position = Vector3.ZERO
	var c = CarryRelationCls.new(rider, platform)
	c.update()
	c.update()
	c.update()
	var ok: bool = absf(rider.global_position.x - 5.0) < 0.001
	rider.queue_free()
	platform.queue_free()
	runner._check(ok, "13.3 carry: platform stationary -> rider unchanged")

func _test_13_carry_rebase(runner: Node) -> void:
	var rider := Node3D.new()
	var platform := Node3D.new()
	runner.add_child(rider)
	runner.add_child(platform)
	platform.global_position = Vector3.ZERO
	rider.global_position = Vector3.ZERO
	var c = CarryRelationCls.new(rider, platform)
	# platform 跳到 x=10，但 rebase → 不应触发 carry
	platform.global_position = Vector3(10, 0, 0)
	c.rebase()
	c.update()
	var ok: bool = absf(rider.global_position.x - 0.0) < 0.001
	rider.queue_free()
	platform.queue_free()
	runner._check(ok, "13.4 carry rebase: skips accumulated dx, rider stays put")

func _test_13_carry_null_safe(runner: Node) -> void:
	var c = CarryRelationCls.new(null, null)
	c.update()  # 不应崩
	var lone := Node3D.new()
	runner.add_child(lone)
	var c2 = CarryRelationCls.new(lone, null)
	c2.update()  # 不应崩
	lone.queue_free()
	runner._check(true, "13.5 carry null safe: update() no-op when nodes null")
