extends Node3D

@export var hex_display_scene: PackedScene
@export var hex_size := 0.65
@export var max_radius: int = 2
@export var ghost_scene: PackedScene
@export var enable_ghost_preview := false

var ghosts := []

var hexes := {}
var current_coord := Vector2i(0, 0)

const DIRECTIONS := [
	Vector2i(0, -1),   # 0 上
	Vector2i(1, -1),   # 1 右上
	Vector2i(1, 0),    # 2 右下
	Vector2i(0, 1),    # 3 下
	Vector2i(-1, 1),   # 4 左下
	Vector2i(-1, 0),   # 5 左上
]

func _ready():
	create_hex(Vector2i(0, 0))

func _input(event):
	if event.is_action_pressed("ui_up"):
		add_next(0)
	if event.is_action_pressed("ui_right"):
		add_next(2)
	if event.is_action_pressed("ui_down"):
		add_next(3)
	if event.is_action_pressed("ui_left"):
		add_next(5)
	if enable_ghost_preview and event.is_action_pressed("ui_accept"):
		show_available_ghosts()

func add_next(direction: int):
	var next_coord = current_coord + DIRECTIONS[direction]
	clear_ghosts()
	
	if not is_inside_wall(next_coord):
		print("超出收藏牆範圍：", next_coord)
		return

	if hexes.has(next_coord):
		current_coord = next_coord
		print("已存在，切換目前盒子：", next_coord)
		return

	create_hex(next_coord)
	current_coord = next_coord

func create_hex(coord: Vector2i):
	if hex_display_scene == null:
		print("沒有指定 HexDisplay.tscn")
		return

	var hex = hex_display_scene.instantiate()
	add_child(hex)

	hex.position = hex_to_position(coord)
	hex.name = "Hex_%d_%d" % [coord.x, coord.y]

	hexes[coord] = hex
	print("生成盒子：", coord, " 位置：", hex.position)

func hex_to_position(coord: Vector2i) -> Vector3:
	var q = coord.x
	var r = coord.y

	var x = hex_size * 1.5 * q
	var y = hex_size * sqrt(3.0) * (r + q * 0.5)

	return Vector3(x, y, 0)
	
func is_inside_wall(coord: Vector2i) -> bool:
	var q := coord.x
	var r := coord.y
	var s := -q - r

	return max(abs(q), abs(r), abs(s)) <= max_radius
	
func clear_ghosts():
	for ghost in ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	ghosts.clear()
	
func show_available_ghosts():
	clear_ghosts()

	for i in range(DIRECTIONS.size()):
		var coord = current_coord + DIRECTIONS[i]

		if not is_inside_wall(coord):
			continue

		if hexes.has(coord):
			continue

		var ghost = ghost_scene.instantiate()
		add_child(ghost)
		ghost.position = hex_to_position(coord)
		ghost.name = "Ghost_%d" % i

		ghosts.append(ghost)

func unlock_ghost_preview():
	enable_ghost_preview = true
	show_available_ghosts()
	
	
