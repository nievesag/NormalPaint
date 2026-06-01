extends Node

var primary_color : Color
var secondary_color : Color

var brush_mask: Image
var brush_size: float = 10
var brush_strength: float = 1.0

func _process(delta:float) -> void:
	print(Engine.get_frames_per_second())