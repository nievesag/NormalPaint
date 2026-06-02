extends TextureRect

func _ready() -> void:
	#	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	stretch_mode = STRETCH_SCALE
	expand_mode = EXPAND_IGNORE_SIZE
	resize_cursor(Global.brush_size)

func _process(delta: float) -> void:
	self.position = self.get_global_mouse_position() - self.size * 0.5
	#cursor.pivot_offset = (cursor.size / 2.0)

func resize_cursor(_size: float) -> void:
	var brush_pixels := maxf(1.0, _size)
	var cursor_size := Vector2(brush_pixels, brush_pixels)
	custom_minimum_size = cursor_size
	size = cursor_size

func change_cursor(_texture: Texture) -> void:
	self.texture = _texture
	resize_cursor(Global.brush_size)

func _on_cursor_resized() -> void:
	self.pivot_offset_ratio = Vector2(0.5,0.5)
	#print_debug("asdasdsadasdasdasdasdasd", cursor.size / 2.0, " ", cursor.pivot_offset)
