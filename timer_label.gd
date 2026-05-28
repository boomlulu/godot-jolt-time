extends Label

@export var timeline_path: NodePath

var _timeline: Timeline = null

func _ready() -> void:
	if not timeline_path.is_empty():
		var n := get_node_or_null(timeline_path)
		if n is Timeline:
			_timeline = n

func bind_timeline(t: Timeline) -> void:
	_timeline = t

func _process(_delta: float) -> void:
	if _timeline == null:
		return
	var remaining := maxf(0.0, _timeline.total_duration - _timeline.current_time)
	var total_ms := int(remaining * 1000.0)
	var m := total_ms / 60000
	var s := (total_ms / 1000) % 60
	var ms := total_ms % 1000
	text = "%02d:%02d:%03d" % [m, s, ms]
