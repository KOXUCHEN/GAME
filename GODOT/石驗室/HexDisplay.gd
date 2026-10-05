extends Node3D

@export var gem_name: String = ""
@export var occupied := false

@onready var gem_slot = $"寶石盒/GemSlot"
@onready var spotlight = $"寶石盒/SpotLight3D"
@onready var animation_player = $"動畫"
@onready var audio_player = $"音效"
@onready var snap_points = $SnapPoints

func get_snap_point(index: int) -> Marker3D:
	return snap_points.get_node("Snap_%d" % index)
