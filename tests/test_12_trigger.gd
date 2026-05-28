extends Node

# Trigger 通用基类（res://trigger.gd）

func run_all(runner: Node) -> void:
	await _test_12_trigger_emits(runner)
	await _test_12_trigger_filter_mismatch(runner)
	await _test_12_trigger_once(runner)
	await _test_12_trigger_untrigger(runner)
	await _test_12_trigger_reset(runner)

func _make_trigger(runner: Node) -> Area3D:
	var t = load("res://trigger.gd").new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 2)
	shape.shape = box
	t.add_child(shape)
	runner.add_child(t)
	return t

func _test_12_trigger_emits(runner: Node) -> void:
	var t = _make_trigger(runner)
	var captured: Array = []
	t.triggered.connect(func(b): captured.append(b))
	var actor := CharacterBody3D.new()
	runner.add_child(actor)
	# 直接调内部 handler 模拟 body_entered（headless 物理 query 不可靠）
	t._on_body_entered(actor)
	var ok: bool = captured.size() == 1
	actor.queue_free()
	t.queue_free()
	runner._check(ok, "12.1 Trigger emits triggered on matching body")

func _test_12_trigger_filter_mismatch(runner: Node) -> void:
	var t = _make_trigger(runner)
	t.target_class_name = "CharacterBody3D"
	var captured: Array = []
	t.triggered.connect(func(b): captured.append(b))
	var rb := RigidBody3D.new()  # 类型不匹配
	runner.add_child(rb)
	t._on_body_entered(rb)
	var ok: bool = captured.size() == 0
	rb.queue_free()
	t.queue_free()
	runner._check(ok, "12.2 Trigger filters non-matching class")

func _test_12_trigger_once(runner: Node) -> void:
	var t = _make_trigger(runner)
	t.once = true
	var count: Array = [0]
	t.triggered.connect(func(_b): count[0] += 1)
	var actor := CharacterBody3D.new()
	runner.add_child(actor)
	t._on_body_entered(actor)
	t._on_body_entered(actor)
	t._on_body_entered(actor)
	var ok: bool = count[0] == 1
	actor.queue_free()
	t.queue_free()
	runner._check(ok, "12.3 Trigger once: only first triggers")

func _test_12_trigger_untrigger(runner: Node) -> void:
	var t = _make_trigger(runner)
	var exit_count: Array = [0]
	t.untriggered.connect(func(_b): exit_count[0] += 1)
	var actor := CharacterBody3D.new()
	runner.add_child(actor)
	t._on_body_exited(actor)
	var ok: bool = exit_count[0] == 1
	actor.queue_free()
	t.queue_free()
	runner._check(ok, "12.4 Trigger emits untriggered on body_exited")

func _test_12_trigger_reset(runner: Node) -> void:
	var t = _make_trigger(runner)
	t.once = true
	var count: Array = [0]
	t.triggered.connect(func(_b): count[0] += 1)
	var actor := CharacterBody3D.new()
	runner.add_child(actor)
	t._on_body_entered(actor)  # 1
	t.reset()
	t._on_body_entered(actor)  # 2
	var ok: bool = count[0] == 2
	actor.queue_free()
	t.queue_free()
	runner._check(ok, "12.5 Trigger reset() clears once gate")
