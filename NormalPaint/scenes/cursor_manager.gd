extends Node2D

@export var cursor: TextureRect # mascara asociada a este pincel

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _process(delta: float) -> void:
	self.position = self.get_global_mouse_position()

func resize_cursor(size: float) -> void:
	cursor.set_size(Vector2(size,size))

func change_cursor(texture: Texture) -> void:
	cursor.texture = texture
