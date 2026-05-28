extends Node3D

const TEST_MODULES := [
	preload("res://tests/test_b_rewindable.gd"),
	preload("res://tests/test_c_touch_button.gd"),
	preload("res://tests/test_d_timer_label.gd"),
	preload("res://tests/test_1_activity.gd"),
	preload("res://tests/test_2_base_level.gd"),
	preload("res://tests/test_3_bug_report.gd"),
	preload("res://tests/test_4_gm_panel.gd"),
	preload("res://tests/test_5_level_smoke.gd"),
	preload("res://tests/test_6_misc.gd"),
	preload("res://tests/test_7_sine.gd"),
	preload("res://tests/test_8_asserts.gd"),
	preload("res://tests/test_9_custom_state.gd"),
	preload("res://tests/test_10_timescale.gd"),
	preload("res://tests/test_11_gravity.gd"),
	preload("res://tests/test_12_trigger.gd"),
	preload("res://tests/test_13_carry.gd"),
]

var _failures: Array = []
var _passes: int = 0

func _ready() -> void:
	await get_tree().physics_frame  # 让 _ready 后物理系统就绪
	for mod_script in TEST_MODULES:
		var mod := Node.new()
		mod.set_script(mod_script)
		add_child(mod)
		await mod.run_all(self)
		mod.queue_free()
	_print_summary_and_quit()

func _check(ok: bool, name: String) -> void:
	if ok:
		_passes += 1
		print("[PASS] " + name)
	else:
		_failures.append(name)
		printerr("[FAIL] " + name)

# 等价断言：自动把 expected/actual 拼进 FAIL 消息
func _assert_equal(actual, expected, name: String) -> void:
	var ok: bool = actual == expected
	if ok:
		_check(true, name)
	else:
		_check(false, "%s: expected %s got %s" % [name, str(expected), str(actual)])

# 容差断言（float）：|actual - expected| <= tolerance
func _assert_near(actual: float, expected: float, tolerance: float, name: String) -> void:
	var delta: float = absf(actual - expected)
	var ok: bool = delta <= tolerance
	if ok:
		_check(true, name)
	else:
		_check(false, "%s: |%.4f - %.4f| = %.4f > %.4f" % [name, actual, expected, delta, tolerance])

func _print_summary_and_quit() -> void:
	print("---")
	print("PASS: %d  FAIL: %d" % [_passes, _failures.size()])
	if _failures.size() > 0:
		for f in _failures:
			print("  - " + f)
		get_tree().quit(1)
	else:
		print("ALL TESTS PASSED")
		get_tree().quit(0)
