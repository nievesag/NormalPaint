extends HSlider

@export_category("Cursor")
@export var cursor: TextureRect
@export var label: Label

func _ready() -> void:
	resize_brush(self.value)
	pass

func resize_brush(_value: float) -> void:
	Global.brush_size = round(_value)
	
	if cursor != null && cursor.has_method("resize_cursor"):
		cursor.call("resize_cursor", _value)
	label.text = "Brush size: %dpx" % self.value
	
