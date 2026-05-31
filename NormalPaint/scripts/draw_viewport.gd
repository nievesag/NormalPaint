extends SubViewport

@export var paint_mat : ShaderMaterial
@onready var brush: Node2D = $Brush

func _ready() -> void:
	paint_mat.set_shader_parameter("paint", get_texture())
	pass

# encapsula a brush
func paint(position: Vector2, color: Color = Color(1,0,0)):
	print_debug("dsadasdsadsadsadasdsadsadsadsadsadsadsad")
	brush.queue_brush(position * 128, color) # * resolucion de la textura del viewport