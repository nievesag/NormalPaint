extends Node

const EXPORT_DIR := "user://exports"

@export var shader_manager: Node
@export var label: Label
@export_range(0.25, 30.0, 0.25) var tween_duration : float = 5.0
var _label_tween: Tween

func _ready() -> void:
	if label != null:
		label.modulate = Color.TRANSPARENT

func _on_albedo_button_up() -> void:
	_export_texture(false, "albedo")

func _on_mapa_normales_button_up() -> void:
	_export_texture(true, "normal_map")

func _export_texture(export_normal_map: bool, base_name: String) -> void:
	var texture: Texture2D = null
	if export_normal_map:
		if shader_manager.has_method("get_working_normal_map"):
			texture = shader_manager.call("get_working_normal_map") as Texture2D
	else:
		if shader_manager.has_method("get_working_albedo"):
			texture = shader_manager.call("get_working_albedo") as Texture2D

	var image := texture.get_image()
	if image == null:
		push_error("No se pudo extraer la imagen de la textura a exportar.")
		return
	if image.is_compressed():
		image.decompress()

	DirAccess.make_dir_recursive_absolute(EXPORT_DIR)
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := "%s/%s_%s.png" % [EXPORT_DIR, base_name, timestamp]
	var error := image.save_png(path)
	if error != OK:
		label.text = ("Error al exportar textura a %s" % path)
		_flash_label()
		return
	label.text = "Textura exportada en: %s" % ProjectSettings.globalize_path(path)
	_flash_label()

func _flash_label() -> void:
	if label == null:
		return

	if _label_tween != null and _label_tween.is_running():
		_label_tween.kill()

	label.modulate = Color.TRANSPARENT
	_label_tween = create_tween()
	_label_tween.tween_property(label, "modulate", Color(0.99215686, 0.96862745, 0.81960785), 0.2)
	_label_tween.tween_interval(tween_duration)
	_label_tween.tween_property(label, "modulate", Color.TRANSPARENT, 0.2)
	
