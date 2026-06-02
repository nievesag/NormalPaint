extends Node

var rd: RenderingDevice
var shader: RID
var pipeline: RID
var _params_buffer: RID
var _color_param_buffer: RID
var _mask_rid: RID
var _cached_mask_id: int = -1

func _ready():
	rd = RenderingServer.get_rendering_device()
	if rd == null:
		push_warning("No hay RenderingDevice disponible; el pintado por compute quedara desactivado.")
		return
	print("Acelerador usado: " + rd.get_device_name())

	# carga shader
	var shader_file: RDShaderFile = load("res://assets/materials/shaders/compute_shader.glsl")
	# compila shader
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	# shader pipeline
	pipeline = rd.compute_pipeline_create(shader)

	var empty_params: PackedByteArray = PackedByteArray()
	empty_params.resize(9 * 4)
	_params_buffer = rd.storage_buffer_create(empty_params.size(), empty_params)

	var empty_color: PackedByteArray = PackedByteArray()
	empty_color.resize(3 * 4)
	_color_param_buffer = rd.storage_buffer_create(empty_color.size(), empty_color)

func _free_rid_if_valid(rid: RID) -> void:
	if rd == null:
		return
	if rid.is_valid():
		rd.free_rid(rid)

func _ensure_mask_texture() -> bool:
	if Global.brush_mask == null:
		push_error("Mascara de pincel nula")
		return false

	var current_mask_id := Global.brush_mask.get_instance_id()
	if _mask_rid.is_valid() and _cached_mask_id == current_mask_id:
		return true

	var mask_image: Image = Global.brush_mask.duplicate()
	mask_image.convert(Image.FORMAT_RGBAF)
	if mask_image.has_mipmaps():
		mask_image.clear_mipmaps()

	var mask_view := RDTextureView.new()
	var mask_format := RDTextureFormat.new()
	mask_format.width = mask_image.get_width()
	mask_format.height = mask_image.get_height()
	mask_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	mask_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)

	_free_rid_if_valid(_mask_rid)
	_mask_rid = rd.texture_create(mask_format, mask_view, [mask_image.get_data()])
	_cached_mask_id = current_mask_id
	return _mask_rid.is_valid()
	
func setup_compute(texture: Texture2D, uv: Vector2, color: Color) -> Texture2D:
	if rd == null:
		return texture
	if texture == null:
		push_error("setup_compute recibio una textura nula")
		return null

	var image: Image = texture.get_image()
	if image == null:
		push_error("Imagen de textura nula")
		return null
	# parametros para el shader
	var mask_w := Global.brush_mask.get_width()
	var mask_h := Global.brush_mask.get_height()
	
	# escalamos la uv a coordenadas sobre la textura real y las usamos como centro de la "circunferencia"
	var cx := (uv.x * float(texture.get_width())) 
	var cy := (uv.y * float(texture.get_height())) 
	var size := maxf(1.0, Global.brush_size)  # para que no pueda ser 0
	var diameter := size
	var radius := size * 0.5
	var needs_srgb_to_linear_image: bool = not (texture is Texture2DRD)
	var paint_color: Color = color
	paint_color = color.srgb_to_linear()

	# ---------- BUFFERS
	# parametros para pasar al shader
	# 0
	var input_data: PackedByteArray = PackedFloat32Array([image.get_width(), image.get_height(), mask_w, mask_h, cx, cy, diameter, radius, Global.brush_strength]).to_byte_array()
	rd.buffer_update(_params_buffer, 0, input_data.size(), input_data)
	# 1
	# ---------- TEXTURES
	# imagenes para pasar al shader
	# ---- mascara
	if not _ensure_mask_texture():
		return null
	
	# ---- image
	# imagen para pasar al shader
	if image.is_compressed():
		image.decompress()
	if image.has_mipmaps():
		image.clear_mipmaps()
	if needs_srgb_to_linear_image and (image.get_format() == Image.FORMAT_RGB8 or image.get_format() == Image.FORMAT_RGBA8):
		image.srgb_to_linear()
	image.convert(Image.FORMAT_RGBAF)

	var input_data_1: PackedByteArray = PackedFloat32Array([paint_color.r, paint_color.g, paint_color.b]).to_byte_array()
	rd.buffer_update(_color_param_buffer, 0, input_data_1.size(), input_data_1)
	
	var texture_view := RDTextureView.new()
	var texture_format := RDTextureFormat.new()
	#tamaños de textura y de máscara
	texture_format.width = image.get_width()
	texture_format.height = image.get_height()

	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT

	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	) 
	
	var texture_rid: RID
	var existing_texture_rd := texture as Texture2DRD
	if existing_texture_rd != null:
		texture_rid = existing_texture_rd.texture_rd_rid
		rd.texture_update(texture_rid, 0, image.get_data())
	else:
		texture_rid = rd.texture_create(texture_format, texture_view, [image.get_data()])
	
	return _compute(texture, texture_rid, diameter)

func _compute(texture: Texture2D, texture_rid: RID, diameter: float) -> Texture2D:
	var parameter_uniform: RDUniform = RDUniform.new()
	parameter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameter_uniform.binding = 0
	parameter_uniform.add_id(_params_buffer)
	
	var color_parameter_uniform: RDUniform = RDUniform.new()
	color_parameter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	color_parameter_uniform.binding = 3
	color_parameter_uniform.add_id(_color_param_buffer)
	
	var mask_uniform: RDUniform = RDUniform.new()
	mask_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	mask_uniform.binding = 1
	mask_uniform.add_id(_mask_rid)
	
	var texture_uniform: RDUniform = RDUniform.new()
	texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	texture_uniform.binding = 2
	texture_uniform.add_id(texture_rid)

	var uniform_set: RID = rd.uniform_set_create([parameter_uniform, mask_uniform, texture_uniform, color_parameter_uniform], shader, 0)
	var compute_list: int = rd.compute_list_begin()

	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	var groups_x := int(ceil(diameter / 32.0))
	var groups_y := int(ceil(diameter / 32.0))
	rd.compute_list_dispatch(compute_list, groups_x, groups_y, 1)
	rd.compute_list_end()

	rd.free_rid(uniform_set)
	
	var existing_texture_rd := texture as Texture2DRD
	if existing_texture_rd != null:
		return existing_texture_rd

	var texture_rd: Texture2DRD = Texture2DRD.new()
	texture_rd.texture_rd_rid = texture_rid
	return texture_rd
