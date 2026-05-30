extends Button

@export_category("Pinceles")
@export var brush_mask: Image # mascara asociada a este pincel

func select_brush() -> void:
	Global.brush_mask = brush_mask