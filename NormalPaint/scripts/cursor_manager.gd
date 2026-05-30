extends TextureRect

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta: float) -> void:
	self.position = self.get_global_mouse_position()
	#cursor.pivot_offset = (cursor.size / 2.0)

func resize_cursor(_size: float) -> void:
	self.set_size(Vector2(_size,_size))

func change_cursor(_texture: Texture) -> void:
	self.texture = _texture

func _on_cursor_resized() -> void:
	self.pivot_offset_ratio = Vector2(0.5,0.5)
	#print_debug("asdasdsadasdasdasdasdasd", cursor.size / 2.0, " ", cursor.pivot_offset)
