extends RigidBody3D

# 道具运动是 ItemTimeline.current_time 的纯函数：正弦左右摇摆
@export var home_x: float = 0.0
@export var home_z: float = 0.0
@export var amplitude: float = 1.4
@export var frequency_hz: float = 0.5
@export var phase: float = 0.0

var timeline: Timeline = null

func _ready() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true

func _physics_process(_delta: float) -> void:
	if timeline == null:
		return
	if timeline.is_locked():
		return
	var t: float = timeline.current_time
	var target_x: float = home_x + sin(t * frequency_hz * TAU + phase) * amplitude
	global_position = Vector3(target_x, global_position.y, home_z)
