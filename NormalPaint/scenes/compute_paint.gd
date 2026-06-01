extends Node

var thread: Thread
var semaphore: Semaphore
var mutex: Mutex
var exit := false

var paint_texture: ViewportTexture

var rd: RenderingDevice
var shader
var pipeline
var buffer

@export var image_n: Image # mascara
@export var image_total: Image # textura

func _ready():
	rd = RenderingServer.get_rendering_device()

	# carga shader
	var shader_file = load("res://materials/shaders/compute_shader.glsl")
	# compila shader
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	# shader pipeline
	pipeline = rd.compute_pipeline_create(shader)
	
	# parametros para el shader
	var mask_w := Global.brush_mask.get_width()
	var mask_h := Global.brush_mask.get_height()
	
	# escalamos la uv a coordenadas sobre la textura real y las usamos como centro de la "circunferencia"
	var cx := (0.5 * float(image_total.get_width())) # 0.5 es la u
	var cy := (0.5 * float(image_total.get_height())) # 0.5 es la v
	var size := maxf(1.0, 400.0)  #para que no pueda ser 0 y ademas tratamos brush size como radio (no se si esta bien pero me venía de refactorizarlo de la ecuación del círculo
	var diameter := size
	var radius := size * 0.5
	var color : Vector4 = Vector4(1.0,0.0,0.0,1.0)
#	if Global.showing_normals:
#		color = Global.secondary_color
#	else:
#		color = Global.primary_color
	
	# parametros para pasar al shader
	var input_data := PackedFloat32Array([image_total.get_width(), image_total.get_height(), mask_w, mask_h, cx, cy, diameter, radius, Global.brush_strength, color]).to_byte_array()
	var storage_buffer: RID = rd.storage_buffer_create(input_data.size(), input_data)
	
	var input_data_1 := PackedFloat32Array([1.0,0.0,0.0]).to_byte_array()
	var storage_buffer_1: RID = rd.storage_buffer_create(input_data_1.size(), input_data_1)
	
	# imagen para pasar al shader
	image_n.convert(Image.FORMAT_RGBAF)
	
	var texture_view := RDTextureView.new()
	
	var texture_format := RDTextureFormat.new()
	#tamaños de textura y de máscara
	texture_format.width = image_n.get_width()
	texture_format.height = image_n.get_height()

	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT

	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	) 

	var texture: RID = rd.texture_create(texture_format, texture_view, [image_n.get_data()])
	
	# imagen para pasar al shader
	image_total.convert(Image.FORMAT_RGBAF)
	
	var texture_view_1 := RDTextureView.new()
	
	var texture_format_1 := RDTextureFormat.new()
	#tamaños de textura y de máscara
	texture_format_1.width = image_total.get_width()
	texture_format_1.height = image_total.get_height()

	texture_format_1.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT

	texture_format_1.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	) 

	var texture_1: RID = rd.texture_create(texture_format_1, texture_view_1, [image_total.get_data()])
	
	_compute(storage_buffer,storage_buffer_1, texture, texture_1)

func _compute(storage_buffer: RID, storage_buffer_1: RID, texture: RID, texture_1: RID):
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
	rd.compute_list_dispatch(compute_list, int(ceil(image_n.get_width() / 8.0)), int(ceil(image_n.get_height() / 8.0)), 1) # ejecuta el shader, settea el num de work groups
	rd.compute_list_end()
	
	var texture_rd := Texture2DRD.new()
	texture_rd.texture_rd_rid = texture_1
	$"../Compute/OutputSprite2D".texture = texture_rd
