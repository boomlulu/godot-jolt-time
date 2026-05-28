extends Node

func run_all(runner: Node) -> void:
	_test_d_timer_label_format(runner)
	_test_d_timer_label_zero(runner)

# D: TimerLabel 根据 Timeline 渲染剩余时间
func _test_d_timer_label_format(runner: Node) -> void:
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	tl.total_duration = 20.0
	tl.current_time = 5.0
	runner.add_child(tl)
	var lbl := Label.new()
	lbl.set_script(load("res://timer_label.gd"))
	lbl.bind_timeline(tl)
	runner.add_child(lbl)
	lbl._process(0.0)
	var ok := lbl.text == "00:15:000"
	var actual := lbl.text
	lbl.queue_free()
	tl.queue_free()
	runner._check(ok, "D1 timer label remaining=15s -> '00:15:000', got '%s'" % actual)

# D: current_time >= total_duration 时显示 00:00:000
func _test_d_timer_label_zero(runner: Node) -> void:
	var tl := Node.new()
	tl.set_script(load("res://timeline.gd"))
	tl.total_duration = 20.0
	tl.current_time = 25.0
	runner.add_child(tl)
	var lbl := Label.new()
	lbl.set_script(load("res://timer_label.gd"))
	lbl.bind_timeline(tl)
	runner.add_child(lbl)
	lbl._process(0.0)
	var ok := lbl.text == "00:00:000"
	var actual := lbl.text
	lbl.queue_free()
	tl.queue_free()
	runner._check(ok, "D2 timer label overflow -> '00:00:000', got '%s'" % actual)
