extends Node

signal camera_changed(active_camera: Camera3D)

var player_camera: Camera3D
var active_instrument_camera: Camera3D

func register_player_camera(camera: Camera3D) -> void:
	player_camera = camera
	_set_current_camera(player_camera)

func enter_instrument_camera(instrument_camera: Camera3D) -> void:
	if instrument_camera == null:
		push_warning("Instrument camera is missing.")
		return

	active_instrument_camera = instrument_camera
	_set_current_camera(active_instrument_camera)

func exit_instrument_camera() -> void:
	active_instrument_camera = null
	if player_camera != null:
		_set_current_camera(player_camera)

func _set_current_camera(camera: Camera3D) -> void:
	if camera == null:
		return

	if player_camera != null:
		player_camera.current = false
	if active_instrument_camera != null:
		active_instrument_camera.current = false

	camera.current = true
	camera_changed.emit(camera)
