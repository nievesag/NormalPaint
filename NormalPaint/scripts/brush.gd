extends Node2D

@export var texture: Texture2D # textura del pincel
@export var brush_size: int = 50 # textura del pincel

var brush_queue: Array[Variant] = []

func queue_brush(pos: Vector2, color: Color):
	brush_queue.push_back([pos, color])
	queue_redraw() # llama a _draw

func _draw():
	for b in brush_queue:
		draw_texture_rect(texture, Rect2(b[0].x - brush_size/2.0, b[0].y - brush_size/2.0, brush_size, brush_size), false, b[1])
	brush_queue = []