extends Node

signal mode_changed(new_mode: Mode, previous_mode: Mode)

enum Mode {
	WALK,
	INSTRUMENT
}

var current_mode: Mode = Mode.WALK

func set_mode(new_mode: Mode) -> void:
	if current_mode == new_mode:
		return

	var previous_mode := current_mode
	current_mode = new_mode
	mode_changed.emit(current_mode, previous_mode)

func is_walk() -> bool:
	return current_mode == Mode.WALK

func is_instrument() -> bool:
	return current_mode == Mode.INSTRUMENT
