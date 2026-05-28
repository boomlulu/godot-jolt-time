class_name Trigger
extends Area3D

# 通用触发器基类。子类（switch / pressure plate / teleporter / key 等）继承复用。
# 当前 Door / Key 走旧路径（base_level 模板方法 + level_02 自管 Area3D），不强制迁移。

signal triggered(body: Node3D)
signal untriggered(body: Node3D)

# 是否单次触发（first match 后忽略后续 enter，直到 reset()）
@export var once: bool = false

# 目标过滤：内置 Node 类名（"CharacterBody3D" / "RigidBody3D" 等）
# 空字符串 = 不过滤，所有 body 都接受
# 也匹配 script path 包含此字符串（便于过滤自定义 class_name actor）
@export var target_class_name: String = "CharacterBody3D"

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _matches(body: Node) -> bool:
	if target_class_name.is_empty():
		return true
	if body.is_class(target_class_name):
		return true
	var scr: Script = body.get_script()
	if scr != null and target_class_name in str(scr.get_path()):
		return true
	return false

func _on_body_entered(body: Node3D) -> void:
	if not _matches(body):
		return
	if _triggered and once:
		return
	_triggered = true
	triggered.emit(body)

func _on_body_exited(body: Node3D) -> void:
	if not _matches(body):
		return
	untriggered.emit(body)

# 子类/外部可重置 once 守卫
func reset() -> void:
	_triggered = false
