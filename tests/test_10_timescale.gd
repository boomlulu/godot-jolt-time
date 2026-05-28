extends Node

# Timeline.timescale 多速率时间

func run_all(runner: Node) -> void:
	_test_10_normal_scale(runner)
	_test_10_slowmo(runner)
	_test_10_fastfwd(runner)
	_test_10_frozen(runner)
	_test_10_negative_treated_as_frozen(runner)

func _make_timeline(runner: Node, scale: float) -> Timeline:
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	tl.total_duration = 20.0
	tl.timescale = scale
	runner.add_child(tl)
	return tl

func _test_10_normal_scale(runner: Node) -> void:
	var tl := _make_timeline(runner, 1.0)
	tl.advance(0.5)
	var ct: float = tl.current_time
	tl.queue_free()
	runner._assert_near(ct, 0.5, 0.001, "10.1 timescale=1.0 advance(0.5) -> +0.5")

func _test_10_slowmo(runner: Node) -> void:
	var tl := _make_timeline(runner, 0.3)
	tl.advance(1.0)
	var ct: float = tl.current_time
	tl.queue_free()
	runner._assert_near(ct, 0.3, 0.001, "10.2 timescale=0.3 advance(1.0) -> +0.3")

func _test_10_fastfwd(runner: Node) -> void:
	var tl := _make_timeline(runner, 2.0)
	tl.advance(0.5)
	var ct: float = tl.current_time
	tl.queue_free()
	runner._assert_near(ct, 1.0, 0.001, "10.3 timescale=2.0 advance(0.5) -> +1.0")

func _test_10_frozen(runner: Node) -> void:
	var tl := _make_timeline(runner, 0.0)
	tl.advance(1.0)
	var ct: float = tl.current_time
	tl.queue_free()
	runner._assert_near(ct, 0.0, 0.001, "10.4 timescale=0 advance(1.0) -> +0 (frozen)")

func _test_10_negative_treated_as_frozen(runner: Node) -> void:
	var tl := _make_timeline(runner, -1.0)
	tl.advance(1.0)
	var ct: float = tl.current_time
	tl.queue_free()
	runner._assert_near(ct, 0.0, 0.001, "10.5 timescale=-1 advance(1.0) -> +0 (negative frozen)")
