extends Node3D

@export var camera : Camera3D 
@export_range(0.1, 10000.0, 0.1) var ray_length: float = 10000.0

func _ready() -> void:
	if camera == null:
		print_debug("NO HAY CÁMARA VÁLIDA ASIGNADA, ESCOGIENDO CÁMARA PRINCIPAL")
		camera = get_viewport().get_camera_3d()

func _process(_delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_raycast_uv(get_viewport().get_mouse_position())

func _raycast_uv(mouse_position: Vector2) -> void:
	if camera == null: 
		print_debug("NO HAY CÁMARA VÁLIDA DESDE LA QUE HACER RAYCAST")
		return

	var origin: Vector3 = camera.project_ray_origin(mouse_position)
	var direction: Vector3 = camera.project_ray_normal(mouse_position)
	var to: Vector3 = origin + direction * ray_length

	var query := PhysicsRayQueryParameters3D.create(origin, to)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): 
		print_debug("no se colisionó con nada")
		return

	var uv_value : Variant = hit.get("uv")
	if uv_value is Vector2:
		var hit_uv: Vector2 = uv_value
		print_debug("raycast UV: ", hit_uv)
	else:
		print_debug("raycast sin UV: ", hit.collider)
