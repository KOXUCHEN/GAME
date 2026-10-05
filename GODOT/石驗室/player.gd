extends CharacterBody3D

const SPEED = 2.0
const SPRINT_SPEED = 4.0
const MOUSE_SENSITIVITY = 0.003
const INSTRUMENT_AIM_DISTANCE = 2.2
const INSTRUMENT_AIM_DOT = 0.88

const SIT_MAX_YAW = 35.0
const SIT_MIN_PITCH = -27.0
const SIT_MAX_PITCH = -6.0

var is_sitting := false
var is_seat_transitioning := false
var pitch := 0.0
var sit_yaw := 0.0
var focused_instrument: Instrument
var default_camera_transform: Transform3D
var default_head_transform: Transform3D
var pre_sit_transform: Transform3D
var pre_sit_head_rotation := Vector3.ZERO
var pre_sit_pitch := 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

@onready var sit_point: Marker3D = $"../Chair/SitPoint"
@onready var look_target: Marker3D = $"../Chair/LookTarget"
@onready var camera_point: Marker3D = $"../Chair/CameraPoint"

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interact_ray.add_exception(self)
	interact_ray.collide_with_areas = true
	interact_ray.collision_mask = 3
	default_camera_transform = camera.transform
	default_head_transform = head.transform
	CameraManager.register_player_camera(camera)

func _input(event: InputEvent) -> void:
	if not GameMode.is_walk():
		return

	if event is InputEventMouseMotion:
		if is_sitting:
			var new_yaw = rotation.y - event.relative.x * MOUSE_SENSITIVITY

			rotation.y = clamp(
				new_yaw,
				sit_yaw - deg_to_rad(SIT_MAX_YAW),
				sit_yaw + deg_to_rad(SIT_MAX_YAW)
			)

			pitch -= event.relative.y * MOUSE_SENSITIVITY
			pitch = clamp(
				pitch,
				deg_to_rad(SIT_MIN_PITCH),
				deg_to_rad(SIT_MAX_PITCH)
			)

			head.rotation.x = pitch
			return

		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		head.rotation.x = pitch

func _physics_process(delta: float) -> void:
	update_instrument_prompt()

	if GameMode.is_instrument():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if Input.is_action_just_pressed("interact"):
		if is_sitting:
			stand_up()
		else:
			try_interact()

	if is_sitting:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var current_speed := SPEED
	if Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var direction := (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func try_interact() -> void:
	if not interact_ray.is_colliding():
		var aimed_instrument := get_aimed_instrument()
		if aimed_instrument != null:
			aimed_instrument.enter_instrument(self)
		return

	var obj = interact_ray.get_collider()
	print("按下E，射線碰到：", obj.name)

	var instrument := get_instrument_from_node(obj)
	if instrument == null:
		instrument = get_aimed_instrument()
	if instrument != null and instrument.can_player_use(self):
		instrument.enter_instrument(self)
		return

	if obj.is_in_group("chair") or obj.get_parent().is_in_group("chair"):
		sit_down()
		return

	if obj.has_method("interact"):
		obj.interact(self)
		return

func sit_down() -> void:
	if is_sitting or is_seat_transitioning:
		return

	is_sitting = true
	is_seat_transitioning = true
	velocity = Vector3.ZERO
	pre_sit_transform = global_transform
	pre_sit_head_rotation = head.rotation
	pre_sit_pitch = pitch

	var dir = look_target.global_position - sit_point.global_position
	dir.y = 0
	var target_y_rotation = atan2(-dir.x, -dir.z)

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"global_position",
		sit_point.global_position,
		0.3
	)

	tween.tween_property(
		self,
		"rotation:y",
		target_y_rotation,
		0.3
	)

	tween.tween_property(
		camera,
		"global_position",
		camera_point.global_position,
		0.3
	)

	tween.finished.connect(func():
		look_at_table()
		start_table_mode()
		is_seat_transitioning = false
	)

func look_at_table() -> void:
	var dir = look_target.global_position - global_position
	dir.y = 0

	rotation.y = atan2(-dir.x, -dir.z)
	sit_yaw = rotation.y

	pitch = deg_to_rad(-12)
	head.rotation.x = pitch

func start_table_mode() -> void:
	print("開始桌面操作模式")

func stand_up() -> void:
	if not is_sitting or is_seat_transitioning:
		return

	is_seat_transitioning = true
	velocity = Vector3.ZERO
	UIManager.hide_prompt()

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_transform", pre_sit_transform, 0.25)
	tween.tween_property(head, "rotation", pre_sit_head_rotation, 0.25)
	tween.tween_property(camera, "transform", default_camera_transform, 0.25)

	tween.finished.connect(func():
		pitch = pre_sit_pitch
		head.position = default_head_transform.origin
		head.rotation = pre_sit_head_rotation
		camera.transform = default_camera_transform
		is_sitting = false
		is_seat_transitioning = false
	)

func update_instrument_prompt() -> void:
	if not GameMode.is_walk() or is_sitting:
		set_focused_instrument(null)
		return

	if not interact_ray.is_colliding():
		set_focused_instrument(get_aimed_instrument())
		return

	var instrument := get_instrument_from_node(interact_ray.get_collider())
	if instrument == null:
		instrument = get_aimed_instrument()
	if instrument != null and not instrument.can_player_use(self):
		instrument = null
	set_focused_instrument(instrument)

func set_focused_instrument(instrument: Instrument) -> void:
	if focused_instrument == instrument:
		return

	if focused_instrument != null:
		focused_instrument.set_highlighted(false)

	focused_instrument = instrument
	if focused_instrument != null:
		focused_instrument.set_highlighted(true)
		UIManager.show_prompt(focused_instrument.get_prompt_text())
	else:
		UIManager.hide_prompt()

func get_instrument_from_node(node: Node) -> Instrument:
	var current := node
	while current != null:
		if current is Instrument:
			return current
		current = current.get_parent()

	return null

func get_aimed_instrument() -> Instrument:
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z
	var best_instrument: Instrument
	var best_score := -1.0

	for node in get_tree().get_nodes_in_group("instrument"):
		var instrument := node as Instrument
		if instrument == null or instrument.is_active:
			continue
		if not instrument.can_player_use(self):
			continue

		var to_instrument := instrument.global_position - origin
		var distance := to_instrument.length()
		if distance > INSTRUMENT_AIM_DISTANCE or distance <= 0.001:
			continue

		var direction := to_instrument / distance
		var dot := forward.dot(direction)
		if dot < INSTRUMENT_AIM_DOT:
			continue

		var score := dot - distance * 0.05
		if score > best_score:
			best_score = score
			best_instrument = instrument

	return best_instrument
