extends Button

@export_category("Pinceles")
@export var brush_mask: Image # mascara asociada a este pincel
@export_category("Cursor")
@export var cursor: TextureRect
@export var brush_cursor: Texture # cursor asociado a este pincel

func select_brush() -> void:
	Global.brush_mask = brush_mask
	
	if cursor != null && brush_cursor != null && cursor.has_method("change_cursor"):
		cursor.call("change_cursor", brush_cursor)
	if cursor != null && cursor.has_method("resize_cursor"):
		cursor.call("resize_cursor", Global.brush_size)
