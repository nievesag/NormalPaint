extends Node3D

@export var subject: MeshInstance3D
@export_category("Materiales")
@export var texture_material: BaseMaterial3D
@export var normal_material: ShaderMaterial
var _showing_normal := false

@export_category("Texturas")
@export var default_normal_map: Image
@export var texture_size := Vector2i(1024, 1024)

func _ready() -> void:
	_apply_current_material()
	var normal_map := _get_normal_map()
	normal_map = _paint_mask_in_image(normal_map, Vector2(0.5, 0.5), Global.foreground_color)
	_set_normal_map(normal_map)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_view"):
		_showing_normal = not _showing_normal
		_apply_current_material()


func _apply_current_material() -> void:
	if subject == null:
		print_debug("NO HAY SUJETO ASIGNADO EN SHADER MANAGER")
		return

	var material := normal_material as Material if _showing_normal else texture_material
	if material == null:
		print_debug("NO HAY MATERIAL VALIDO ASIGNADO EN SHADER MANAGER")
		return

	subject.set_surface_override_material(0, material)


func _get_normal_map() -> ImageTexture:
	if texture_material == null:
		push_error("texture_material no asignado")
		return null

	var normal_map := texture_material.get_texture(BaseMaterial3D.TEXTURE_NORMAL) as ImageTexture
	if normal_map == null:
		print_debug("La mesh no tiene normal map, creandolo")
		if default_normal_map == null:
			default_normal_map = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
			default_normal_map.fill(Color(0.5, 0.5, 1.0, 1.0))
		normal_map = ImageTexture.create_from_image(default_normal_map)
		_set_normal_map(normal_map)

	return normal_map


func _set_normal_map(tex: ImageTexture) -> void:
	if tex == null:
		push_error("Se esta intentando aplicar un normal map nulo")
		return

	if texture_material != null:
		texture_material.normal_enabled = true
		texture_material.set_texture(BaseMaterial3D.TEXTURE_NORMAL, tex)

	if normal_material != null:
		normal_material.set_shader_parameter("normal_tex", tex)


func _paint_mask_in_image(texture: ImageTexture, uv: Vector2, color: Color) -> ImageTexture:
	if texture == null:
		push_error("Imposible pintar en textura nula")
		return null

	var image := texture.get_image()
	if image == null:
		push_error("Imagen de textura nula")
		return null

	if Global.brush_mask == null:
		push_error("Mascara de pincel nula")
		return texture

	var w := image.get_width()
	var h := image.get_height()
	var mask_w := Global.brush_mask.get_width()
	var mask_h := Global.brush_mask.get_height()

	var cx := int(uv.x * float(w))
	var cy := int((1.0 - uv.y) * float(h))
	var size := maxi(1, Global.brush_size)
	var diameter := size * 2
	var half: int = size

	# lo qeu acabará siendo el shader de cómputo
	for y in range(cy - half, cy + half):
		for x in range(cx - half, cx + half):
			if x < 0 or y < 0 or x >= w or y >= h:
				continue

			var local_x := x - (cx - half)
			var local_y := y - (cy - half)
			var u := clampf(float(local_x) / float(maxi(1, diameter - 1)), 0.0, 1.0)
			var v := clampf(float(local_y) / float(maxi(1, diameter - 1)), 0.0, 1.0)
			var mx := int(round(u * float(mask_w - 1)))
			var my := int(round(v * float(mask_h - 1)))

			var mask_px := Global.brush_mask.get_pixel(mx, my)
			var mask_value := clampf(mask_px.r, 0.0, 1.0) * Global.brush_strength
			if mask_value <= 0.0:
				continue

			var base := image.get_pixel(x, y)
			image.set_pixel(x, y, base.lerp(color, mask_value))

	texture.update(image)
	return texture
