extends SubViewport

@onready var brush: Node2D = $Brush

# encapsula a brush
func paint(position: Vector2, color: Color = Color(1,1,1)):
	brush.queue_brush(position * 1024, color) # * resolucion de la textura del viewport