extends Node3D

@export_category("Dibujo")
@export var camera : Camera3D 
@export_range(0.1, 10000.0, 0.1) var ray_length: float = 10000.0
@export var _meshInstance : MeshInstance3D
@export var _shader_manager: Node

@export_category("Color")
@onready var _colorpicker : ColorPickerButton = $"../../UI/ColorPickerButton"

@export_category("Pinceles")
@export var default_brush_mask: Image # mascara asociada a este pincel

var mdt: MeshDataTool

var _numFaces := 0 # numero de caras triangulares de la mesh
var _worldNormals := PackedVector3Array() # array de las normales de cada cara
var _worldVertices := [] # array de posiciones de vertices en el mundo
var _localFaceVertices := [] # array de los vertices locales a la mesh

# pruebas
var _vertices
var _uvs
var _indices

func _ready() -> void:
	if camera == null:
		print_debug("NO HAY CÁMARA VÁLIDA ASIGNADA, ESCOGIENDO CÁMARA PRINCIPAL")
		camera = get_viewport().get_camera_3d()
		
	if _meshInstance == null:
		print_debug("NO HAY MESHINSTANCE3D VÁLIDA ASIGNADA")
		return
	
	if _colorpicker != null:
		Global.foreground_color = _colorpicker.color
		
	Global.brush_mask = default_brush_mask
	
	mdt = MeshDataTool.new()
	var mesh: Mesh = _meshInstance.mesh
	
	if mesh == null:
		print_debug("LA MESH DE LA MESHINSTANCE3D NO ES VÁLIDA")
		return
	
	var arrays: Array = mesh.surface_get_arrays(0)
	# info de la mesh ->
	_vertices = arrays[Mesh.ARRAY_VERTEX]
	_uvs = arrays[Mesh.ARRAY_TEX_UV]
	_indices = arrays[Mesh.ARRAY_INDEX]
	
	# saco en arraymesh del mesh de la meshinstance para poder pasarselo a create_from_surface
	var arrMesh: ArrayMesh = ArrayMesh.new()
	arrMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.get_mesh_arrays())
	
	mdt.create_from_surface(arrMesh, 0) # rellena la info del meshdatatool con la data de la mesh especificada
	_numFaces = mdt.get_face_count()
	_worldNormals.resize(_numFaces) # mismo numero de normales que de caras
	
	for i in range(_numFaces):
		_worldNormals[i] = to_global(mdt.get_face_normal(i)) # calcula la normal de cada cara
		
		# los vertices para cada indice de una cara triangular
		# i0 ---- i1
		#  \      /
		#   \    /
		#    \  /
		#     i2
		var i0: int = mdt.get_face_vertex(i, 0)
		var i1: int = mdt.get_face_vertex(i, 1)
		var i2: int = mdt.get_face_vertex(i, 2)
		
		_localFaceVertices.push_back([i0, i1, i2])
		
		_worldVertices.push_back([
			to_global((mdt.get_vertex(i0))),
			to_global((mdt.get_vertex(i1))),
			to_global((mdt.get_vertex(i2)))
		])
		
func _process(_delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_raycast_uv(get_viewport().get_mouse_position())

func _cart2bary(p : Vector3, a : Vector3, b : Vector3, c: Vector3) -> Vector3:
	print_debug(a, " ", b, " ", c, " .. ", p)
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a

#	var pb := b - p
#	var pc := c - p
#	var pa := a - p
#	var cr: Vector3 = (v0.cross(v1))
#	var area: float = (cr).length() / 2
#	print_debug("AREAAAAA: ", area)
#
#	# https://math.stackexchange.com/questions/4322/check-whether-a-point-is-within-a-3d-triangle
#	var alfa_cr: Vector3 = (pb.cross(pc))
#	var beta_cr: Vector3 = (pc.cross(pa))
#	var alfa: float = (alfa_cr).length() / 2 * area
#	var beta: float = (beta_cr).length()  / 2 * area
#	var gamma: float = 1.0 - alfa - beta
#	print_debug("peter: ", alfa, " ", beta, " ", gamma)
#	return Vector3(alfa, beta, gamma)
	
# https://github.com/Arnklit/WaterwaysDemo/blob/014c15121ddec26b5cab7f70218414bad0bb3b5d/addons/waterways/water_helper_methods.gd#L20
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denom := d00 * d11 - d01 * d01
	var v: float = (d11 * d20 - d01 * d21) / denom
	var w: float = (d00 * d21 - d01 * d20) / denom
	var u: float = 1.0 - v - w
	var bc: Vector3 = Vector3(u, v, w)
#	print_debug(bc)
#	print_debug("----------")
	return bc

# https://blackpawn.com/texts/pointinpoly/
#	var v0 := c - a
#	var v1 := b - a
#	var v2 := p - a
#	
#	var d00 := v0.dot(v0)
#	var d01 := v0.dot(v1)
#	var d02 := v0.dot(v2)
#	var d11 := v1.dot(v1)
#	var d12 := v1.dot(v2)
#	
#	var invDenom := 1 / (d00 * d11 - d01 * d01)
#	
#	var u: float = (d11 * d02 - d01 * d12) * invDenom
#	var v: float = (d00 * d12 - d01 * d02) * invDenom
#	var w: float = 1.0 - u - v
#	
#	# Check if point is in triangle
#	if (u >= 0) && (v >= 0) && (u + v < 1): 
#		print_debug("estoy dentro")
	
	#print_debug(u, " ", v, " " ,w)
	
	#return Vector3(u, v, w)
	
#	var v0 := b - a
#	var v1 := c - a
#	var v2 := p - a
#	var d00 := v0.dot(v0)
#	var d01 := v0.dot(v1)
#	var d11 := v1.dot(v1)
#	var d20 := v2.dot(v0)
#	var d21 := v2.dot(v1)
#	var denom := d00 * d11 - d01 * d01
#	var v = (d11 * d20 - d01 * d21) / denom
#	var w = (d00 * d21 - d01 * d20) / denom
#	var u = 1.0 - v - w
#	return Vector3(u, v, w)
	
func _is_point_in_triangle(point, v1, v2, v3) -> Vector3:
	var bc: Vector3 = _cart2bary(point, v1, v2, v3)
	var sum: float = round(bc.x + bc.y + bc.z)
	print_debug("suma ", sum)
	if (bc.x >= 0 && bc.x <= 1) && (bc.y >= 0 && bc.y <= 1) && (bc.z >= 0 && bc.z <= 1) && (sum == 1):
		return bc
	
	return Vector3()

func _get_face_info(point, normal, epsilon = 0.2) -> Array:
	for i in range(_numFaces):
		var world_normal: Vector3 = _worldNormals[i]
		
		if !(world_normal.distance_to(normal) < epsilon):
			continue
			
		var vertices = _worldVertices[i]
		
		var bc: Vector3 = _is_point_in_triangle(point, vertices[0], vertices[1], vertices[2])
		
		if bc:
			return [i, vertices, bc] # info: cara, vertices, baricentro
			
	return Array()

func _raycast_uv(mouse_position: Vector2) -> void:
	if camera == null: 
		print_debug("NO HAY CÁMARA VÁLIDA DESDE LA QUE HACER RAYCAST")
		return

	# 			direction
	# origin ----------------> to
	var origin: Vector3 = camera.project_ray_origin(mouse_position)
	var direction: Vector3 = camera.project_ray_normal(mouse_position)
	var to: Vector3 = origin + direction * ray_length
	# query del rayo que queremos lanzar, estructura para definir los parametros del rayo
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	# lanza el rayo
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	
	if hit.is_empty():  # si no se da a nada
		print_debug("no se colisionó con nada")
		return
						# si se da a algo
	var pos: Vector3 = hit["position"]
	var nor: Vector3 = hit["normal"]
	var coll: Object = hit["collider"] # el objeto asociado a ese collider
	print("position ", pos)
	print("normal ", nor)
	print("collider ", coll)
	
	if(_meshInstance == null):
		print("mesh instance null")
		return
		
	if(_meshInstance.mesh == null):
		print("mesh null")
		return
		
	if(mdt == null):
		print("MeshDataTool null")
		return

	var face_index_variant: Variant = hit.get("face_index", -1)
	if face_index_variant is int:
		var face_index: int = face_index_variant
		if face_index >= 0 and face_index < mdt.get_face_count():
			var i0: int = mdt.get_face_vertex(face_index, 0)
			var i1: int = mdt.get_face_vertex(face_index, 1)
			var i2: int = mdt.get_face_vertex(face_index, 2)

			var p_local: Vector3 = _meshInstance.to_local(pos)
			var a_local: Vector3 = mdt.get_vertex(i0)
			var b_local: Vector3 = mdt.get_vertex(i1)
			var c_local: Vector3 = mdt.get_vertex(i2)
			var bc: Vector3 = _cart2bary(p_local, a_local, b_local, c_local)

			var uv0: Vector2 = mdt.get_vertex_uv(i0)
			var uv1: Vector2 = mdt.get_vertex_uv(i1)
			var uv2: Vector2 = mdt.get_vertex_uv(i2)
			var uv_from_face: Vector2 = uv0 * bc.x + uv1 * bc.y + uv2 * bc.z
			print("UV!!!!!!!!!! ", uv_from_face)
			if _shader_manager != null and _shader_manager.has_method("paint_at_uv"):
				_shader_manager.call("paint_at_uv", uv_from_face)
			return
	
#	var uv: Vector2 = Vector2()
#	var min_dist = INF # va guardando la distancia mas pequeña hasta el momento
#	
#	for i in range(0, _indices.size(), 3): # coge los indices de 3 en 3
#		for j in range(3): # recorre cada uno de los 3 vertices de una cara
#			var v = _indices[i + j] # coge el indice que estamos recorriendo del array de indices totales
#			var v_world = _meshInstance.global_transform * _vertices[v] # posicion en el mundo
#			var dist: float = to_global(pos).distance_to(v_world) # distancia entre el vertice que evaluo y la pos de colision del rayo
#			
#			if dist < min_dist: # si la nueva distancia calculada es menor que la ultima hasta ahora
#				min_dist = dist # se sobreescribe
#				uv = _uvs[v] # guardo la uv asociada a ese vertice
#
#	print("UV!!!!!!!!!!: ", uv)
#	if _shader_manager != null and _shader_manager.has_method("paint_at_uv"):
#		_shader_manager.call("paint_at_uv", uv)
		
#	var face: Array = _get_face_info(to_global(pos), to_global(nor))
#	
#	if !face:
#		print("face null")
#		return
#
#	var bc = face[2]
#	
#	var uv1: Vector2 = mdt.get_vertex_uv(_localFaceVertices[face[0]][0]) # vertice 0 de la cara
#	var uv2: Vector2 = mdt.get_vertex_uv(_localFaceVertices[face[0]][1]) # vertice 1 de la cara
#	var uv3: Vector2 = mdt.get_vertex_uv(_localFaceVertices[face[0]][2]) # vertice 2 de la cara
#
#	var uv = (uv1 * bc.x) + (uv2 * bc.y) + (uv3 * bc.z)
	#print("!!!!!!!!!!! UV", uv)
	
func _on_color_picker_button_color_changed(color: Color) -> void:
	Global.foreground_color = color
	pass # Replace with function body.
