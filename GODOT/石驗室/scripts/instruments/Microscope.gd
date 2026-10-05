extends Instrument
class_name Microscope

signal focus_changed(focus_value: float, blur_amount: float, is_focused: bool)
signal inclusions_revealed(inclusions: Array[String])
signal gem_identified(gem: GemData)

@export var current_gem: GemData
@export_range(0.0, 100.0, 1.0) var focus_value := 50.0
@export var focus_tolerance := 5.0
@export var focus_step := 2.0
@export var max_blur_amount := 1.0
@export var max_eye_yaw_degrees := 3.0
@export var max_eye_pitch_degrees := 3.0
@export var eye_mouse_sensitivity := 0.002
@export_node_path("Node3D") var mask_path: NodePath
@export_node_path("Node3D") var gem_holder_path: NodePath

var blur_amount := 1.0
var revealed_inclusions: Array[String] = []
var camera_base_transform := Transform3D.IDENTITY
var eye_yaw := 0.0
var eye_pitch := 0.0
var has_reported_identification := false

@onready var mask_node: Node3D = get_node_or_null(mask_path) as Node3D
@onready var gem_holder: Node3D = get_node_or_null(gem_holder_path) as Node3D

func _ready() -> void:
	super._ready()
	if display_name == "Instrument":
		display_name = "Microscope"

	var camera := get_instrument_camera()
	if camera != null:
		camera_base_transform = camera.transform
		_setup_camera_dof(camera)

	_setup_mask()
	_set_mask_visible(false)
	_update_gem_visibility()
	_update_focus_state()

func _on_entered() -> void:
	eye_yaw = 0.0
	eye_pitch = 0.0

	var camera := get_instrument_camera()
	if camera != null:
		camera.transform = camera_base_transform
		_setup_camera_dof(camera)

	_set_mask_visible(true)
	_update_gem_visibility()
	UIManager.show_microscope_ui()
	_update_focus_state()

func _on_exited() -> void:
	_set_mask_visible(false)
	UIManager.hide_microscope_ui()
	revealed_inclusions.clear()

	var camera := get_instrument_camera()
	if camera != null:
		camera.transform = camera_base_transform

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if not is_active:
		return

	if event is InputEventMouseMotion:
		_update_eye_offset(event.relative)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("focus_up"):
		_adjust_focus(focus_step)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("focus_down"):
		_adjust_focus(-focus_step)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_focus(focus_step)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_focus(-focus_step)
			get_viewport().set_input_as_handled()

func _update_eye_offset(relative: Vector2) -> void:
	var camera := get_instrument_camera()
	if camera == null:
		return

	eye_yaw -= relative.x * eye_mouse_sensitivity
	eye_pitch -= relative.y * eye_mouse_sensitivity
	eye_yaw = clampf(eye_yaw, deg_to_rad(-max_eye_yaw_degrees), deg_to_rad(max_eye_yaw_degrees))
	eye_pitch = clampf(eye_pitch, deg_to_rad(-max_eye_pitch_degrees), deg_to_rad(max_eye_pitch_degrees))

	camera.transform = camera_base_transform
	camera.rotate_object_local(Vector3.RIGHT, eye_pitch)
	camera.rotate_object_local(Vector3.UP, eye_yaw)

func _adjust_focus(amount: float) -> void:
	focus_value = clampf(focus_value + amount, 0.0, 100.0)
	_update_focus_state()

func _update_focus_state() -> void:
	var correct_focus := 50.0
	var inclusions: Array[String] = []

	if current_gem != null:
		correct_focus = current_gem.correct_focus
		inclusions = current_gem.possible_inclusions

	var distance := absf(focus_value - correct_focus)
	var is_focused := current_gem != null and distance <= focus_tolerance
	blur_amount = clampf(distance / 35.0 * max_blur_amount, 0.0, max_blur_amount)

	if current_gem == null:
		blur_amount = 0.35

	_apply_dof_blur(blur_amount)

	if is_focused:
		revealed_inclusions = inclusions.duplicate()
		inclusions_revealed.emit(revealed_inclusions)
		_report_gem_identified_once()
	else:
		revealed_inclusions.clear()

	focus_changed.emit(focus_value, blur_amount, is_focused)
	UIManager.update_microscope_ui(focus_value, blur_amount, revealed_inclusions, is_focused)

func _report_gem_identified_once() -> void:
	if has_reported_identification or current_gem == null:
		return

	has_reported_identification = true
	gem_identified.emit(current_gem)

	for node in get_tree().get_nodes_in_group("collection_builder"):
		if node.has_method("unlock_next_box_slot"):
			node.unlock_next_box_slot()

func _setup_mask() -> void:
	if mask_node == null:
		return

	_apply_material_to_meshes(mask_node, _create_mask_material())

func _create_mask_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 mask_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float radius = 0.34;
uniform float softness = 0.015;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	float alpha = smoothstep(radius, radius + softness, dist);
	ALBEDO = mask_color.rgb;
	ALPHA = alpha;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _apply_material_to_meshes(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material

	for child in node.get_children():
		_apply_material_to_meshes(child, material)

func _set_mask_visible(visible: bool) -> void:
	if mask_node != null:
		mask_node.visible = visible

func _update_gem_visibility() -> void:
	if gem_holder == null:
		return

	for child in gem_holder.get_children():
		if child is Node3D:
			(child as Node3D).visible = current_gem != null

func _setup_camera_dof(camera: Camera3D) -> void:
	var attributes := camera.attributes as CameraAttributesPractical
	if attributes == null:
		attributes = CameraAttributesPractical.new()
		camera.attributes = attributes

	attributes.dof_blur_near_enabled = true
	attributes.dof_blur_far_enabled = true
	attributes.dof_blur_near_distance = 0.12
	attributes.dof_blur_near_transition = 0.08
	attributes.dof_blur_far_distance = 0.35
	attributes.dof_blur_far_transition = 0.16
	attributes.dof_blur_amount = blur_amount

func _apply_dof_blur(amount: float) -> void:
	var camera := get_instrument_camera()
	if camera == null:
		return

	var attributes := camera.attributes as CameraAttributesPractical
	if attributes == null:
		_setup_camera_dof(camera)
		attributes = camera.attributes as CameraAttributesPractical

	if attributes != null:
		attributes.dof_blur_amount = amount
