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

var texture: ImageTexture
var texture_path: String

#func _ready():
#	rd = RenderingServer.create_local_rendering_device()
#
#	# carga shader
#	var shader_file := load("res://materials/shaders/compute_shader.glsl")
#	# compila shader
#	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
#	shader = rd.shader_create_from_spirv(shader_spirv)
#	# shader pipeline
#	pipeline = rd.compute_pipeline_create(shader)
#	
#	var image = texture.get_image()
#	image.convert(Image.FORMAT_RGBAF)
#	var texture_view := RDTextureView.new()
#	var texture_format := RDTextureFormat.new()
#	#tamaños de textura y de máscara
#	texture_format.width = image.get_width()
#	texture_format.height = image.get_height()
#	var mask_w := Global.brush_mask.get_width()
#	var mask_h := Global.brush_mask.get_height()
#	
#	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
#
#	texture_format.usage_bits = (
#		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
#		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
#		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
#	)
#	
#	var texture := rd.texture_create(texture_format, texture_view, [image.get_data()])
#	
#	var image_uniform := RDUniform.new()
#	image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
#	image_uniform.binding = 0
#	image_uniform.add_id(texture)
#	
#	var uniform_set := rd.uniform_set_create([image_uniform], shader, 0)
#	var compute_list := rd.compute_list_begin()
#	
#	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
#	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
#	rd.compute_list_dispatch(compute_list, 32, 32, 1) # ejecuta el shader, settea el num de work groups
#	rd.compute_list_end()
#	
#	
	
#	#metodo para pintar la máscara de pincel actual en una posición uv de la textura dada con un color para la máscara
#    func _paint_mask_in_image(texture: ImageTexture, uv: Vector2, color: Color) -> ImageTexture:
#    	#programacion defensiva
#    	if texture == null:
#    		push_error("Imposible pintar en textura nula")
#    		return null
#    
#    	var image := texture.get_image()
#    	if image == null:
#    		push_error("Imagen de textura nula")
#    		return null
#    
#    	if Global.brush_mask == null:
#    		push_error("Mascara de pincel nula")
#    		return texture
#    
#    	#tamaños de textura y de máscara
#    	var w := image.get_width()
#    	var h := image.get_height()
#    	var mask_w := Global.brush_mask.get_width()
#    	var mask_h := Global.brush_mask.get_height()
#    
#    	#escalamos la uv a coordenadas sobre la textura real y las usamos como centro de la "circunferencia"
#    	var cx := int(uv.x * float(w))
#    	var cy := int(uv.y * float(h))
#    	var size := maxi(1, Global.brush_size)  #para que no pueda ser 0 y ademas tratamos brush size como radio (no se si esta bien pero me venía de refactorizarlo de la ecuación del círculo
#    	var diameter := size * 2
#    	var half: int = size
#    
#    	# lo qeu acabará siendo el shader de cómputo
#    	for y in range(cy - half, cy + half):
#    		for x in range(cx - half, cx + half):
#    			if x < 0 or y < 0 or x >= w or y >= h: # si se sale no hacer nada
#    				continue
#    
#    			#pos local del píxel actual dentro del cuadrado del pincel
#    			# cx - half / cy - half es la esquina superior izquierda del area a pintar en principio
#    			var local_x := x - (cx - half)
#    			var local_y := y - (cy - half)
#    			
#    			#normalizamos la pos local dentro de 0-1
#    			# maxi evita dividir entre 0 si el diametro fuese 1
#    			var u := clampf(float(local_x) / float(maxi(1, diameter - 1)), 0.0, 1.0)
#    			var v := clampf(float(local_y) / float(maxi(1, diameter - 1)), 0.0, 1.0)
#    			
#    			#convertimos esa posición normalizada a coordenadas reales dentro de la máscara del brush
#    			#si u = 0.0 → mx = 0
#    			#si u = 1.0 → mx = mask_w - 1
#    			var mx := int(round(u * float(mask_w - 1)))
#    			var my := int(round(v * float(mask_h - 1)))
#    
#    			var mask_px := Global.brush_mask.get_pixel(mx, my) # pixel de la mascara
#    			var mask_value := clampf(mask_px.r, 0.0, 1.0) * Global.brush_strength #r porque se que es grayscale pero ehh yo que se, y 0 y 1 para que no se salga la fuerza por arriba o por debajo
#    			if mask_value <= 0.0: #si no hace nada
#    				continue
#    
#    			var base := image.get_pixel(x, y) #pixel original
#    			image.set_pixel(x, y, base.lerp(color, mask_value)) #blendeo con el pixel calculado de la mascara en funcion de su fuerza
#    
#    	texture.update(image) #reemplazamos textura
#    	return texture
