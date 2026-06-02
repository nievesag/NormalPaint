extends Node

const EXPORT_DIR := "user://exports"

@export var shader_manager: Node

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
		push_error("Error al exportar textura a %s" % path)
		return
	print("Textura exportada en: ", ProjectSettings.globalize_path(path))
