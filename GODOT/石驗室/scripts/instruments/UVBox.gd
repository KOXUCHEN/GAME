extends Instrument
class_name UVBox

enum WaveMode {
	OFF,
	LONG_WAVE,
	SHORT_WAVE
}

@export_node_path("Light3D") var long_wave_light_path: NodePath
@export_node_path("Light3D") var short_wave_light_path: NodePath
@export var long_wave_color := Color(0.45, 0.22, 1.0, 1.0)
@export var short_wave_color := Color(0.1, 0.45, 1.0, 1.0)
@export var long_wave_energy := 2.4
@export var short_wave_energy := 3.0

var wave_mode := WaveMode.OFF

@onready var long_wave_light: Light3D = get_node_or_null(long_wave_light_path) as Light3D
@onready var short_wave_light: Light3D = get_node_or_null(short_wave_light_path) as Light3D

func _ready() -> void:
	super._ready()
	if display_name == "Instrument":
		display_name = "UV Box"

	_setup_lights()
	_set_wave_mode(WaveMode.OFF)

func _on_entered() -> void:
	_set_wave_mode(WaveMode.LONG_WAVE)
	UIManager.show_uvbox_ui()
	UIManager.update_uvbox_ui("Long Wave", "365 nm", long_wave_color)

func _on_exited() -> void:
	_set_wave_mode(WaveMode.OFF)
	UIManager.hide_uvbox_ui()

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if not is_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_1:
			_set_wave_mode(WaveMode.LONG_WAVE)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_2:
			_set_wave_mode(WaveMode.SHORT_WAVE)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_3:
			_set_wave_mode(WaveMode.OFF)
			get_viewport().set_input_as_handled()

func _setup_lights() -> void:
	if long_wave_light != null:
		long_wave_light.light_color = long_wave_color
		long_wave_light.light_energy = long_wave_energy
		long_wave_light.visible = false

	if short_wave_light != null:
		short_wave_light.light_color = short_wave_color
		short_wave_light.light_energy = short_wave_energy
		short_wave_light.visible = false

func _set_wave_mode(new_mode: WaveMode) -> void:
	wave_mode = new_mode

	if long_wave_light != null:
		long_wave_light.visible = wave_mode == WaveMode.LONG_WAVE
	if short_wave_light != null:
		short_wave_light.visible = wave_mode == WaveMode.SHORT_WAVE

	if not is_active:
		return

	match wave_mode:
		WaveMode.LONG_WAVE:
			UIManager.update_uvbox_ui("Long Wave", "365 nm", long_wave_color)
		WaveMode.SHORT_WAVE:
			UIManager.update_uvbox_ui("Short Wave", "254 nm", short_wave_color)
		_:
			UIManager.update_uvbox_ui("Off", "--", Color.WHITE)
