extends RefCounted

static func format(scene: Node, body: String) -> String:
	return "=== Bug Report ===\nscene: %s\ntime: %s\nengine: %s\nplatform: %s\n--- state ---\n%s" % [
		scene.scene_file_path,
		Time.get_datetime_string_from_system(),
		Engine.get_version_info().get("string", "?"),
		OS.get_name(),
		body,
	]

static func copy(button: Button, scene: Node, body: String) -> void:
	var full := format(scene, body)
	DisplayServer.clipboard_set(full)
	button.text = "已复制"
	var original_modulate = button.modulate
	button.modulate = Color(0.5, 1.0, 0.5, 1.0)
	var tree := button.get_tree()
	if tree:
		await tree.create_timer(1.2).timeout
	button.text = "提交Bug"
	button.modulate = original_modulate
