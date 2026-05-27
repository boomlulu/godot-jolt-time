extends Control

func _on_exit_button_pressed() -> void:
	get_tree().quit()
	OS.kill(OS.get_process_id())
