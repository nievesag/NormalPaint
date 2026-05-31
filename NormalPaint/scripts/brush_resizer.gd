extends SpinBox

@export_category("Cursor")
@export var cursor: TextureRect

func _ready() -> void:
	Global.brush_size = self.value
	resize_brush(self.value)
	pass

func resize_brush(_value: float) -> void:
	Global.brush_size = round(_value)
	
	if cursor != null && cursor.has_method("resize_cursor"):
		cursor.call("resize_cursor", _value)
