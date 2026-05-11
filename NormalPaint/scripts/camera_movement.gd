extends Node3D

#https://github.com/godotengine/godot/blob/master/editor/scene/3d/node_3d_editor_plugin.cpp
#https://docs.godotengine.org/en/stable/classes/class_editorsettings.html
#TODO en el editor de godot el look around del right click sobreescribe el orbit target

@export_group("Velocidad")
@export var speed: float = 8.0
@export var sprint_factor: float = 3.0
@export var acceleration: float = 14.0
@export_group("Sensibilidad")
@export_range(0.001, 0.1, 0.001) var look_sensitivity: float = 0.002
@export_range(0.001, 0.1, 0.01) var pan_sensitivity: float = 0.01
@export_range(0.001, 0.1, 0.001) var orbit_sensitivity: float = 0.004
@export_group("Rotación")
@export_range(-90, 0, 1) var min_pitch_degrees: float = -90.0
@export_range(0, 90, 1) var max_pitch_degrees: float = 90.0
@export var orbit_target: Vector3 = Vector3.ZERO

var _velocity: Vector3 = Vector3.ZERO
var _pitch: float = 0.0

func _ready() -> void:
	_pitch = rotation.x

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_O:
			_target_origin()
			return

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_rotate(event.relative)
			return
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			if Input.is_physical_key_pressed(KEY_SHIFT):
				_pan(event.relative)
			else:
				_orbit(event.relative)

func _rotate(mouse_delta: Vector2) -> void:
	rotation.y -= mouse_delta.x * look_sensitivity
	
	_pitch -= mouse_delta.y * look_sensitivity
	var min_pitch := deg_to_rad(min_pitch_degrees)
	var max_pitch := deg_to_rad(max_pitch_degrees)
	_pitch = clamp(_pitch, min_pitch, max_pitch)
	rotation.x = _pitch

	var orbit_distance := global_position.distance_to(orbit_target)
	orbit_target = global_position + (-global_transform.basis.z * orbit_distance)

func _pan(mouse_delta: Vector2) -> void:
	var pan_local := Vector3(-mouse_delta.x, mouse_delta.y, 0.0) * pan_sensitivity
	var pan_world := global_transform.basis * pan_local
	global_position += pan_world
	orbit_target += pan_world

func _orbit(mouse_delta: Vector2) -> void:
	var to_camera := global_position - orbit_target
	var horizontal_rotation := Basis(Vector3.UP, -mouse_delta.x * orbit_sensitivity)
	to_camera = horizontal_rotation * to_camera

	var right_axis := global_transform.basis.x.normalized()
	var vertical_rotation := Basis(right_axis, -mouse_delta.y * orbit_sensitivity)
	var candidate_to_camera := vertical_rotation * to_camera
	var candidate_forward := (orbit_target - (orbit_target + candidate_to_camera)).normalized()
	var candidate_pitch := asin(clamp(candidate_forward.y, -1.0, 1.0))
	var min_pitch := deg_to_rad(min_pitch_degrees)
	var max_pitch := deg_to_rad(max_pitch_degrees)
	if candidate_pitch >= min_pitch and candidate_pitch <= max_pitch:
		to_camera = candidate_to_camera

	global_position = orbit_target + to_camera
	look_at(orbit_target, Vector3.UP)
	_pitch = rotation.x

func _target_origin() -> void:
	orbit_target = Vector3.ZERO
	look_at(orbit_target, Vector3.UP)
	_pitch = rotation.x

func _process(delta: float) -> void:
	var local_direction := Vector3.ZERO

	if Input.is_physical_key_pressed(KEY_A):
		local_direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		local_direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		local_direction.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		local_direction.z += 1.0

	var direction := (global_transform.basis * local_direction.normalized()).normalized()
	var real_speed := speed
	if Input.is_physical_key_pressed(KEY_SHIFT):
		real_speed *= sprint_factor

	var target_velocity := direction * real_speed
	_velocity = _velocity.lerp(target_velocity, clamp(acceleration * delta, 0.0, 1.0))
	var displacement := _velocity * delta
	global_position += displacement
	orbit_target += displacement
