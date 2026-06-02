extends Node

var rd: RenderingDevice
var shader
var pipeline

func _ready():
	rd = RenderingServer.get_rendering_device()

	# carga shader
	var shader_file = load("res://materials/shaders/compute_shader.glsl")
	# compila shader
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	# shader pipeline
	pipeline = rd.compute_pipeline_create(shader)
	
func _setup_compute(texture: Image, uv: Vector2, color: Color):
	# parametros para el shader
	var mask_w := Global.brush_mask.get_width()
	var mask_h := Global.brush_mask.get_height()
	
	# escalamos la uv a coordenadas sobre la textura real y las usamos como centro de la "circunferencia"
	var cx := (uv.x * float(texture.get_width())) 
	var cy := (uv.y * float(texture.get_height())) 
	var size := maxf(1.0, Global.brush_size)  # para que no pueda ser 0
	var diameter := size
	var radius := size * 0.5
	
	# ---------- BUFFERS
	# parametros para pasar al shader
	# 0
	var input_data := PackedFloat32Array([texture.get_width(), texture.get_height(), mask_w, mask_h, cx, cy, diameter, radius, Global.brush_strength]).to_byte_array()
	var storage_buffer: RID = rd.storage_buffer_create(input_data.size(), input_data)
	# 1
	var input_data_1 := PackedFloat32Array([color.r,color.g,color.b]).to_byte_array()
	var storage_buffer_1: RID = rd.storage_buffer_create(input_data_1.size(), input_data_1)
	
	# ---------- TEXTURES
	# imagenes para pasar al shader
	# ---- mascara
	Global.brush_mask.convert(Image.FORMAT_RGBAF)
	if Global.brush_mask.has_mipmaps():
		Global.brush_mask.clear_mipmaps()
	
	var mask_view := RDTextureView.new()
	var mask_format := RDTextureFormat.new()
	# tamaños de textura y de máscara
	mask_format.width = Global.brush_mask.get_width()
	mask_format.height = Global.brush_mask.get_height()

	mask_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT

	mask_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	) 

	var mask_rid: RID = rd.texture_create(mask_format, mask_view, [Global.brush_mask.get_data()])
	
	# ---- texture
	# imagen para pasar al shader
	texture.convert(Image.FORMAT_RGBAF)
	if texture.has_mipmaps():
		texture.clear_mipmaps()
	
	var texture_view := RDTextureView.new()
	var texture_format := RDTextureFormat.new()
	#tamaños de textura y de máscara
	texture_format.width = texture.get_width()
	texture_format.height = texture.get_height()

	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT

	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	) 

	var texture_rid: RID = rd.texture_create(texture_format, texture_view, [texture.get_data()])
	
	_compute(storage_buffer, storage_buffer_1, mask_rid, texture_rid, texture.get_width(), texture.get_height())

func _compute(storage_buffer: RID, storage_buffer_1: RID, texture: RID, texture_1: RID, texture_w: float, texture_h: float):
	var parameter_uniform := RDUniform.new()
	parameter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameter_uniform.binding = 0
	parameter_uniform.add_id(storage_buffer)
	
	var parameter_uniform_1 := RDUniform.new()
	parameter_uniform_1.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameter_uniform_1.binding = 3
	parameter_uniform_1.add_id(storage_buffer_1)
	
	var image_uniform := RDUniform.new()
	image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_uniform.binding = 1
	image_uniform.add_id(texture)
	
	var image_uniform_1 := RDUniform.new()
	image_uniform_1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_uniform_1.binding = 2
	image_uniform_1.add_id(texture_1)

	var uniform_set := rd.uniform_set_create([parameter_uniform, image_uniform, image_uniform_1, parameter_uniform_1], shader, 0)
	var compute_list := rd.compute_list_begin()

	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, int(ceil(texture_h / 8.0)), int(ceil(texture_w / 8.0)), 1) # ejecuta el shader, settea el num de work groups
	rd.compute_list_end()
	
	var texture_rd := Texture2DRD.new()
	texture_rd.texture_rd_rid = texture_1
	$"../Compute/OutputSprite2D".texture = texture_rd
