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

static func copy_dict(button: Button, scene: Node, state: Dictionary) -> void:
	await copy(button, scene, dict_to_text(state))

static func dict_to_text(d: Dictionary, indent: int = 0) -> String:
	var pad := _pad(indent)
	var lines: Array[String] = []
	for k in d.keys():
		var v = d[k]
		var key_str := str(k)
		match typeof(v):
			TYPE_DICTIONARY:
				if (v as Dictionary).is_empty():
					lines.append("%s%s: {}" % [pad, key_str])
				else:
					lines.append("%s%s:" % [pad, key_str])
					lines.append(dict_to_text(v, indent + 2))
			TYPE_ARRAY:
				lines.append(_format_array_line(key_str, v, indent))
			_:
				lines.append("%s%s: %s" % [pad, key_str, _format_value(v)])
	return "\n".join(lines)

static func _format_array_line(key_str: String, arr: Array, indent: int) -> String:
	var pad := _pad(indent)
	if arr.is_empty():
		return "%s%s: []" % [pad, key_str]
	var first_is_dict := typeof(arr[0]) == TYPE_DICTIONARY
	if first_is_dict:
		var out := "%s%s:" % [pad, key_str]
		var child_pad := _pad(indent + 2)
		for elem in arr:
			if typeof(elem) == TYPE_DICTIONARY:
				var sub := dict_to_text(elem, indent + 4)
				# Replace first line's leading whitespace with "- "
				var first_line_pad := _pad(indent + 4)
				# sub starts with first_line_pad — swap leading pad to dash form
				if sub.begins_with(first_line_pad):
					sub = "%s- %s" % [child_pad, sub.substr(first_line_pad.length())]
				out += "\n" + sub
			else:
				out += "\n%s- %s" % [child_pad, _format_value(elem)]
		return out
	# inline primitives
	var parts: Array[String] = []
	for elem in arr:
		parts.append(_format_value(elem))
	return "%s%s: [%s]" % [pad, key_str, ", ".join(parts)]

static func _format_value(v) -> String:
	match typeof(v):
		TYPE_FLOAT: return "%.3f" % v
		TYPE_BOOL: return str(v)
		TYPE_INT: return str(v)
		TYPE_STRING: return v
		TYPE_VECTOR3, TYPE_VECTOR2, TYPE_COLOR: return str(v)
		_: return str(v)

static func _pad(indent: int) -> String:
	if indent <= 0:
		return ""
	return " ".repeat(indent)
