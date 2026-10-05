extends Resource
class_name GemData

@export var gem_name: String = "Unknown Gem"
@export_range(0.0, 100.0, 1.0) var correct_focus: float = 50.0
@export var possible_inclusions: Array[String] = []
