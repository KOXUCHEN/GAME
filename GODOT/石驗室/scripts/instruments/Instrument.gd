extends Node3D
class_name Instrument

signal instrument_entered(instrument: Instrument)
signal instrument_exited(instrument: Instrument)
signal player_entered_range(instrument: Instrument, player: Node)
signal player_exited_range(instrument: Instrument, player: Node)

@export var display_name: String = "Instrument"
@export_node_path("Camera3D") var instrument_camera_path: NodePath
@export_node_path("Area3D") var interaction_area_path: NodePath
@export var highlight_enabled := true
@export var highlight_color := Color(1.0, 0.74, 0.32, 1.0)
@export_range(0.0, 4.0, 0.1) var highlight_strength := 1.8

var is_active := false
var players_in_range: Array[Node] = []
var is_highlighted := false
var highlight_material: ShaderMaterial
var highlighted_meshes: Array[MeshInstance3D] = []

func _enter_tree() -> void:
	add_to_group("instrument")

func _ready() -> void:
	_build_highlight_material()
	_collect_highlight_meshes(self)

	var area := get_interaction_area()
	if area == null:
		return

	area.body_entered.connect(_on_interaction_body_entered)
	area.body_exited.connect(_on_interaction_body_exited)

func set_highlighted(value: bool) -> void:
	if not highlight_enabled:
		value = false
	if is_highlighted == value:
		return

	is_highlighted = value
	for mesh in highlighted_meshes:
		if mesh == null:
			continue
		mesh.material_overlay = highlight_material if is_highlighted else null

func get_prompt_text() -> String:
	return "E Use %s" % display_name

func can_enter(player: Node = null) -> bool:
	if not GameMode.is_walk() or is_active:
		return false
	if player != null and not can_player_use(player):
		return false
	return true

func can_player_use(player: Node) -> bool:
	return players_in_range.has(player)

func enter_instrument(player: Node = null) -> void:
	if not can_enter(player):
		return

	set_highlighted(false)
	is_active = true
	GameMode.set_mode(GameMode.Mode.INSTRUMENT)
	CameraManager.enter_instrument_camera(get_instrument_camera())
	UIManager.hide_prompt()
	instrument_entered.emit(self)
	_on_entered()

func exit_instrument() -> void:
	if not is_active:
		return

	is_active = false
	_on_exited()
	CameraManager.exit_instrument_camera()
	GameMode.set_mode(GameMode.Mode.WALK)
	instrument_exited.emit(self)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("exit_instrument"):
		get_viewport().set_input_as_handled()
		exit_instrument()

func _on_entered() -> void:
	pass

func _on_exited() -> void:
	pass

func get_instrument_camera() -> Camera3D:
	if instrument_camera_path.is_empty():
		return null
	return get_node_or_null(instrument_camera_path) as Camera3D

func get_interaction_area() -> Area3D:
	if interaction_area_path.is_empty():
		return null
	return get_node_or_null(interaction_area_path) as Area3D

func _build_highlight_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_opaque, cull_back;

uniform vec4 glow_color : source_color = vec4(1.0, 0.74, 0.32, 1.0);
uniform float glow_strength = 1.8;

void fragment() {
	float rim = 1.0 - abs(dot(NORMAL, VIEW));
	rim = smoothstep(0.18, 0.95, rim);
	ALBEDO = glow_color.rgb;
	EMISSION = glow_color.rgb * glow_strength * rim;
	ALPHA = rim * 0.62;
}
"""
	highlight_material = ShaderMaterial.new()
	highlight_material.shader = shader
	highlight_material.set_shader_parameter("glow_color", highlight_color)
	highlight_material.set_shader_parameter("glow_strength", highlight_strength)

func _collect_highlight_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		highlighted_meshes.append(node as MeshInstance3D)

	for child in node.get_children():
		if child == get_interaction_area():
			continue
		if child is Camera3D:
			continue
		_collect_highlight_meshes(child)

func _on_interaction_body_entered(body: Node) -> void:
	if body is CharacterBody3D and not players_in_range.has(body):
		players_in_range.append(body)
		player_entered_range.emit(self, body)

func _on_interaction_body_exited(body: Node) -> void:
	if players_in_range.has(body):
		players_in_range.erase(body)
		player_exited_range.emit(self, body)
