extends Node3D

@export var subject : MeshInstance3D
@export var texture_material : Material 
@export var normal_material : Material 
var _showing_normal := false
@export var mask_image: Image
@export var mask_texture: ImageTexture
@export_range(0.0, 1.0) var brush_strength : float = 1.0

func _ready() -> void:
	_apply_current_material()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_view"):
		_showing_normal = not _showing_normal
		_apply_current_material()

func _apply_current_material() -> void:
	if subject == null:
		print_debug("NO HAY SUJETO ASIGNADO EN SHADER MANAGER")
		return

	var material := normal_material if _showing_normal else texture_material
	if material == null:
		print_debug("NO HAY MATERIAL VALIDO ASIGNADO EN SHADER MANAGER")
		return
		
	subject.set_surface_override_material(0, material)
