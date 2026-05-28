extends Node

# 测试 StateFrame.custom + Rewindable on_capture/on_restore hook

func run_all(runner: Node) -> void:
	_test_9_state_frame_custom_default(runner)
	_test_9_capture_without_hook(runner)
	_test_9_capture_with_hook(runner)
	_test_9_apply_with_hook(runner)
	_test_9_apply_without_hook_no_crash(runner)

func _test_9_state_frame_custom_default(runner: Node) -> void:
	var f := StateFrame.new()
	runner._assert_equal(f.custom.is_empty(), true, "9.1 StateFrame.custom default empty Dictionary")

func _test_9_capture_without_hook(runner: Node) -> void:
	# 没 on_capture hook 的节点（普通 RigidBody3D）capture 后 custom 应该是空 dict
	var rb := RigidBody3D.new()
	runner.add_child(rb)
	var frame := Rewindable.capture(rb, 1.0)
	var ok: bool = frame.custom.is_empty()
	rb.queue_free()
	runner._check(ok, "9.2 Rewindable.capture without on_capture: custom empty")

func _test_9_capture_with_hook(runner: Node) -> void:
	# 自定义脚本带 on_capture：custom 应包含返回的 dict
	var node := _CustomTarget.new()
	runner.add_child(node)
	node.gravity_dir = Vector3.UP
	node.charge = 0.75
	var frame := Rewindable.capture(node, 2.0)
	var ok: bool = (
		frame.custom.get("gravity_dir", Vector3.ZERO) == Vector3.UP
		and absf(frame.custom.get("charge", 0.0) - 0.75) < 0.001
	)
	node.queue_free()
	runner._check(ok, "9.3 Rewindable.capture with on_capture: custom populated")

func _test_9_apply_with_hook(runner: Node) -> void:
	# apply 应该调 on_restore 把 dict 还原到 target
	var node := _CustomTarget.new()
	runner.add_child(node)
	node.gravity_dir = Vector3.UP
	node.charge = 0.5
	var frame := Rewindable.capture(node, 1.0)
	# 修改 node 状态
	node.gravity_dir = Vector3.LEFT
	node.charge = 0.99
	# apply 应恢复
	Rewindable.apply(node, frame)
	var ok: bool = node.gravity_dir == Vector3.UP and absf(node.charge - 0.5) < 0.001
	node.queue_free()
	runner._check(ok, "9.4 Rewindable.apply with on_restore: custom restored")

func _test_9_apply_without_hook_no_crash(runner: Node) -> void:
	# 没 on_restore hook 的节点 apply 时不应崩
	var rb := RigidBody3D.new()
	runner.add_child(rb)
	var frame := StateFrame.new(0.5, Transform3D.IDENTITY, Vector3.ZERO, Vector3.ZERO)
	frame.custom = {"foo": "bar"}  # 即使有 custom，没 hook 就忽略
	Rewindable.apply(rb, frame)
	rb.queue_free()
	runner._check(true, "9.5 Rewindable.apply without on_restore: no crash on extra custom")

# 内部测试用 mock target
class _CustomTarget extends Node3D:
	var gravity_dir: Vector3 = Vector3.DOWN
	var charge: float = 0.0
	func on_capture() -> Dictionary:
		return {"gravity_dir": gravity_dir, "charge": charge}
	func on_restore(d: Dictionary) -> void:
		gravity_dir = d.get("gravity_dir", Vector3.DOWN)
		charge = d.get("charge", 0.0)
