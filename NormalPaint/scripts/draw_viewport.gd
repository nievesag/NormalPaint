extends SubViewport

@onready var brush: Node2D = $Brush

# encapsula a brush
func paint(position: Vector2, color: Color = Color(1,0,0)):
	print_debug("dsadasdsadsadsadasdsadsadsadsadsadsadsad")
	brush.queue_brush(position * 128, color) # * resolucion de la textura del viewport