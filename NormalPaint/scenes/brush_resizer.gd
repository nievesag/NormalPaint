extends SpinBox

@export_category("Cursor")
@export var cursor: Node2D

func resize_brush(_value: float) -> void:
	Global.brush_size = round(_value)
	
	if cursor != null && cursor.has_method("resize_cursor"):
		cursor.call("resize_cursor", _value)
