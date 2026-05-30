extends Node3D

@export var subject: MeshInstance3D
@export_category("Materiales")
@export var texture_material: BaseMaterial3D
@export var normal_material: ShaderMaterial
var _showing_normal := false

@export_category("Texturas")
@export var default_normal_map: Image
@export var texture_size := Vector2i(1024, 1024)
var _working_normal_map: ImageTexture


func _ready() -> void:
	_apply_current_material()
	_working_normal_map = _get_normal_map()
	if _working_normal_map != null:
		_set_normal_map(_working_normal_map)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_view"):
		_showing_normal = not _showing_normal
		_apply_current_material() #aplicamos el material que toque


func _apply_current_material() -> void:
	#programacion defensiva
	if subject == null:
		print_debug("NO HAY SUJETO ASIGNADO EN SHADER MANAGER")
		return

	var material := normal_material as Material if _showing_normal else texture_material # el que toque
	if material == null:
		print_debug("NO HAY MATERIAL VALIDO ASIGNADO EN SHADER MANAGER")
		return

	#aplicamos el material a la mesh, y es el 0 porque al parecer puede haber varios overrides
	subject.mesh.surface_set_material(0, material)

#metodo para recibir el mapa de normales del material de textura
func _get_normal_map() -> ImageTexture:
	#programacion defensiva
	if texture_material == null:
		push_error("texture_material no asignado")
		return null

	#buscamos el mapa de normales en el material de textura
	var normal_map := texture_material.get_texture(BaseMaterial3D.TEXTURE_NORMAL) as ImageTexture
	if normal_map == null:
		print_debug("La mesh no tiene normal map, creandolo")
		if default_normal_map == null: # si no existe ni la textura default se crea una
			default_normal_map = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
			default_normal_map.fill(Color(0.5, 0.5, 1.0, 1.0))
		normal_map = ImageTexture.create_from_image(default_normal_map) # textura por defecto
		_set_normal_map(normal_map)

	return normal_map

#metodo para setear el mapa de normales a ambos materiales
func _set_normal_map(tex: ImageTexture) -> void:
	#programacion defensiva
	if tex == null:
		push_error("Se esta intentando aplicar un normal map nulo")
		return

	#aplicamos el mapa de normales a cada material
	if texture_material != null:
		texture_material.normal_enabled = true
		texture_material.set_texture(BaseMaterial3D.TEXTURE_NORMAL, tex)

	if normal_material != null:
		normal_material.set_shader_parameter("normal_tex", tex)
		
func paint_at_uv(uv: Vector2, color: Color = Global.foreground_color) -> void:
	if _working_normal_map == null:
		_working_normal_map = _get_normal_map()
	if _working_normal_map == null:
		return

	var painted_normal_map := _paint_mask_in_image(_working_normal_map, uv, color)
	if painted_normal_map == null:
		return
	
	_working_normal_map = painted_normal_map
	_set_normal_map(_working_normal_map)


#método para pintar la máscara de pincel actual en una posición uv de la textura dada con un color para la máscara
func _paint_mask_in_image(texture: ImageTexture, uv: Vector2, color: Color) -> ImageTexture:
	#programacion defensiva
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

	#tamaños de textura y de máscara
	var w := image.get_width()
	var h := image.get_height()
	var mask_w := Global.brush_mask.get_width()
	var mask_h := Global.brush_mask.get_height()

	#escalamos la uv a coordenadas sobre la textura real y las usamos como centro de la "circunferencia"
	var cx := uv.x * float(w)
	var cy := uv.y * float(h)
	var size := maxf(1.0, Global.brush_size)  #para que no pueda ser 0 y ademas tratamos brush size como radio (no se si esta bien pero me venía de refactorizarlo de la ecuación del círculo
	var diameter := size * 2
	var half:= size

	# lo qeu acabará siendo el shader de cómputo
	for y in range(cy - half, cy + half):
		for x in range(cx - half, cx + half):
			if x < 0 or y < 0 or x >= w or y >= h: # si se sale no hacer nada
				continue

			#pos local del píxel actual dentro del cuadrado del pincel
			# cx - half / cy - half es la esquina superior izquierda del area a pintar en principio
			var local_x := x - (cx - half)
			var local_y := y - (cy - half)
			
			#normalizamos la pos local dentro de 0-1
			# maxi evita dividir entre 0 si el diametro fuese 1
			var u := clampf(float(local_x) / float(max(1, diameter - 1)), 0.0, 1.0)
			var v := clampf(float(local_y) / float(max(1, diameter - 1)), 0.0, 1.0)
			
			#convertimos esa posición normalizada a coordenadas reales dentro de la máscara del brush
			#si u = 0.0 → mx = 0
			#si u = 1.0 → mx = mask_w - 1
			var mx := int(round(u * float(mask_w - 1)))
			var my := int(round(v * float(mask_h - 1)))

			var mask_px := Global.brush_mask.get_pixel(mx, my) # pixel de la mascara
			var mask_value := clampf(mask_px.r, 0.0, 1.0) * Global.brush_strength #r porque se que es grayscale pero ehh yo que se, y 0 y 1 para que no se salga la fuerza por arriba o por debajo
			if mask_value <= 0.0: #si no hace nada
				continue

			var base := image.get_pixel(x, y) #pixel original
			image.set_pixel(x, y, base.lerp(color, mask_value)) #blendeo con el pixel calculado de la mascara en funcion de su fuerza

	texture.update(image) #reemplazamos textura
	return texture
