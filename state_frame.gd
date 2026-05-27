class_name StateFrame
extends RefCounted

var time: float = 0.0
var transform: Transform3D = Transform3D.IDENTITY
var linear_v: Vector3 = Vector3.ZERO
var angular_v: Vector3 = Vector3.ZERO

func _init(t: float = 0.0, xf: Transform3D = Transform3D.IDENTITY, lv: Vector3 = Vector3.ZERO, av: Vector3 = Vector3.ZERO) -> void:
	time = t
	transform = xf
	linear_v = lv
	angular_v = av
