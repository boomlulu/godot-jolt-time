extends Node

func run_all(runner: Node) -> void:
	_test_c_button_same_frame_dedup(runner)

# C: 同一帧内多次 _emit_once 只 emit 一次 pressed
func _test_c_button_same_frame_dedup(runner: Node) -> void:
	var btn := Button.new()
	btn.set_script(load("res://touch_button.gd"))
	runner.add_child(btn)
	var counter := [0]
	btn.pressed.connect(func(): counter[0] += 1)
	btn._emit_once()
	btn._emit_once()
	btn._emit_once()
	var actual: int = counter[0]
	var ok: bool = actual == 1
	btn.queue_free()
	runner._check(ok, "C1 same-frame emit dedup: expected 1 got %d" % actual)
