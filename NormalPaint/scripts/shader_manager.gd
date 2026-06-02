extends Node3D

@export var subject: MeshInstance3D
@export_category("Materiales")
@export var texture_material: BaseMaterial3D
@export var normal_material: ShaderMaterial

@export_category("Texturas")
@export var default_normal_map: Image
@export var texture_size := Vector2i(1024, 1024)
var _working_normal_map: Texture2D
var _working_albedo_tex: Texture2D

@export var _compute_paint: Node

func _ready() -> void:
	if texture_material != null:
		texture_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_working_albedo_tex = _get_albedo()
	_working_normal_map = _get_normal_map()
	if _working_albedo_tex != null:
		_set_albedo(_working_albedo_tex)
	if _working_normal_map != null:
		_set_normal_map(_working_normal_map)
	_apply_current_material()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_view"):
		Global.showing_normals = not Global.showing_normals
		_apply_current_material() #aplicamos el material que toque


func _apply_current_material() -> void:
	#programacion defensiva
	if subject == null:
		print_debug("NO HAY SUJETO ASIGNADO EN SHADER MANAGER")
		return

	var material: Material = normal_material as Material if Global.showing_normals else texture_material
	if material == null:
		print_debug("NO HAY MATERIAL VALIDO ASIGNADO EN SHADER MANAGER")
		return

	#aplicamos el material a la mesh, y es el 0 porque al parecer puede haber varios overrides
	subject.mesh.surface_set_material(0, material)

#metodo para recibir el mapa de normales del material de textura
func _get_normal_map() -> Texture2D:
	#programacion defensiva
	if texture_material == null:
		push_error("texture_material no asignado")
		return null

	var normal_tex: Texture2D = texture_material.get_texture(BaseMaterial3D.TEXTURE_NORMAL)
	if normal_tex != null:
		return _normalize_working_texture(normal_tex, true)

	print_debug("La mesh no tiene normal map, creándolo...")
	if default_normal_map == null:
		default_normal_map = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBAF)
		default_normal_map.fill(Color(0.5, 0.5, 1.0, 1.0))
	else:
		default_normal_map.convert(Image.FORMAT_RGBAF)
	return ImageTexture.create_from_image(default_normal_map)

func _normalize_working_texture(texture: Texture2D, is_albedo: bool) -> Texture2D:
	if texture == null:
		return null
	if texture is Texture2DRD:
		return texture

	var image: Image = texture.get_image()
	if image == null:
		return texture
	if image.is_compressed():
		image.decompress()
	if image.has_mipmaps():
		image.clear_mipmaps()
	if is_albedo and (image.get_format() == Image.FORMAT_RGB8 or image.get_format() == Image.FORMAT_RGBA8):
		image.srgb_to_linear()
	image.convert(Image.FORMAT_RGBAF)
	return ImageTexture.create_from_image(image)

func _set_normal_map(tex: Texture2D) -> void:
	if tex == null:
		push_error("Se esta intentando aplicar un normal map nulo")
		return

	#aplicamos el mapa de normales a cada material
	if texture_material != null:
		texture_material.normal_enabled = true
		texture_material.set_texture(BaseMaterial3D.TEXTURE_NORMAL, tex)

	if normal_material != null:
		normal_material.set_shader_parameter("normal_tex", tex)
		normal_material.set_shader_parameter("albedo_texture", tex)

func _get_albedo() -> Texture2D:
	if texture_material == null:
		return null
	return _normalize_working_texture(texture_material.get_texture(BaseMaterial3D.TEXTURE_ALBEDO), true)

func _set_albedo(tex: Texture2D) -> void:
	#programacion defensiva
	if tex == null:
		push_error("Se esta intentando aplicar una textura nula")
		return
	if texture_material != null:
		texture_material.set_texture(BaseMaterial3D.TEXTURE_ALBEDO, tex)

func get_working_albedo() -> Texture2D:
	return _working_albedo_tex

func get_working_normal_map() -> Texture2D:
	return _working_normal_map


func paint_at_uv(uv: Vector2) -> void:
	if Global.paint_both:
		if _working_albedo_tex == null: return
		_working_albedo_tex = _paint_mask_in_image(_working_albedo_tex, uv, Global.primary_color)
		if _working_albedo_tex == null: return
		_set_albedo(_working_albedo_tex)
		if _working_normal_map == null: return
		_working_normal_map = _paint_mask_in_image(_working_normal_map, uv, Global.secondary_color)
		if _working_normal_map == null: return
		_set_normal_map(_working_normal_map)
		return
		
	if Global.showing_normals: # pintamos mapa de normales
		if _working_normal_map == null: return
		_working_normal_map = _paint_mask_in_image(_working_normal_map, uv, Global.secondary_color)
		if _working_normal_map == null: return
		_set_normal_map(_working_normal_map)
		return
	
	#pintamos textura
	if _working_albedo_tex == null: return
	_working_albedo_tex = _paint_mask_in_image(_working_albedo_tex, uv, Global.primary_color)
	if _working_albedo_tex == null: return
	_set_albedo(_working_albedo_tex)
		
#metodo para pintar la mascara de pincel actual en una posicion uv de la textura dada con un color para la mascara
func _paint_mask_in_image(texture: Texture2D, uv: Vector2, color: Color) -> Texture2D:
	#programacion defensiva
	if texture == null:
		push_error("Imposible pintar en textura nula")
		return null

	if Global.brush_mask == null:
		push_error("Mascara de pincel nula")
		return texture
		
	if _compute_paint != null and _compute_paint.has_method("setup_compute"):
		var computed_variant: Variant = _compute_paint.call("setup_compute", texture, uv, color)
		if computed_variant is Texture2D:
			return computed_variant as Texture2D
		return null
	return null
	
	
	# VERSIÓN CPU!!!!!!!!!!!
#	#tamaños de textura y de máscara
#	var w := image.get_width()
#	var h := image.get_height()
#	var mask_w := Global.brush_mask.get_width()
#	var mask_h := Global.brush_mask.get_height()
#
#	#escalamos la uv a coordenadas sobre la textura real y las usamos como centro de la "circunferencia"
#	var cx := uv.x * float(w)
#	var cy := uv.y * float(h)
#	var size := maxf(1.0, Global.brush_size)  #para que no pueda ser 0 y ademas tratamos brush size como radio (no se si esta bien pero me venía de refactorizarlo de la ecuación del círculo
#	var diameter := size
#	var radius := size * 0.5
#
#	# lo que acabará siendo el shader de cómputo
#	for y in range(cy - radius, cy + radius):
#		for x in range(cx - radius, cx + radius):
#			var px := posmod(x, w) # funcion de autowrap increible
#			var py := posmod(y, h)
#
#			#pos local del píxel actual dentro del cuadrado del pincel
#			# cx - half / cy - half es la esquina superior izquierda del area a pintar en principio
#			var local_x := x - (cx - radius)
#			var local_y := y - (cy - radius)
#			
#			#normalizamos la pos local dentro de 0-1
#			# max evita dividir entre 0 si el diametro fuese 1
#			var u := clampf(float(local_x) / float(max(1, diameter - 1)), 0.0, 1.0)
#			var v := clampf(float(local_y) / float(max(1, diameter - 1)), 0.0, 1.0)
#			
#			#convertimos esa posición normalizada a coordenadas reales dentro de la máscara del brush
#			#si u = 0.0 → mx = 0
#			#si u = 1.0 → mx = mask_w - 1
#			var mx := int(round(u * float(mask_w - 1)))
#			var my := int(round(v * float(mask_h - 1)))
#
#			var mask_px : Color = Global.brush_mask.get_pixel(mx, my) # pixel de la mascara
#			var mask_value := clampf(mask_px.r, 0.0, 1.0) * Global.brush_strength #r porque se que es grayscale pero ehh yo que se, y 0 y 1 para que no se salga la fuerza por arriba o por debajo
#			if mask_value <= 0.0: #si no hace nada
#				continue
#
#			var base := image.get_pixel(px, py) #pixel original
#			image.set_pixel(px, py, base.lerp(color, mask_value)) #blendeo con el pixel calculado de la mascara en funcion de su fuerza
#
#	texture.update(image) #reemplazamos textura
#	return texture
