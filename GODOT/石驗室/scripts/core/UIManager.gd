extends CanvasLayer

const PANEL_BG := Color(0.035, 0.031, 0.027, 0.78)
const PANEL_BG_STRONG := Color(0.02, 0.018, 0.016, 0.9)
const TEXT_MAIN := Color(0.96, 0.93, 0.86, 1.0)
const TEXT_SOFT := Color(0.74, 0.69, 0.6, 1.0)
const ACCENT := Color(0.95, 0.74, 0.38, 1.0)
const GOOD := Color(0.56, 0.92, 0.62, 1.0)
const WARN := Color(0.95, 0.58, 0.38, 1.0)

var hud_root: Control
var vignette: ColorRect
var crosshair_root: Control
var crosshair_dot: ColorRect
var prompt_panel: PanelContainer
var prompt_label: Label
var mode_label: Label
var objective_label: Label
var hint_label: Label
var microscope_panel: PanelContainer
var focus_label: Label
var focus_bar: ProgressBar
var blur_label: Label
var inclusion_label: Label
var status_label: Label
var uvbox_panel: PanelContainer
var uv_mode_label: Label
var uv_wavelength_label: Label
var uv_status_label: Label
var uv_color_strip: ColorRect

func _ready() -> void:
	layer = 20
	_build_hud()
	_build_vignette()
	_build_top_left_status()
	_build_crosshair()
	_build_prompt()
	_build_hint_bar()
	_build_microscope_panel()
	_build_uvbox_panel()
	set_mode_text("WALK")
	set_objective_text("Gem Lab")
	hide_prompt()
	hide_microscope_ui()
	hide_uvbox_ui()

func show_prompt(text: String) -> void:
	if prompt_label == null or prompt_panel == null:
		return

	prompt_label.text = text.to_upper()
	prompt_panel.visible = true

func hide_prompt() -> void:
	if prompt_panel != null:
		prompt_panel.visible = false

func show_microscope_ui() -> void:
	if microscope_panel != null:
		microscope_panel.visible = true
	if crosshair_root != null:
		crosshair_root.visible = false
	if hint_label != null:
		hint_label.text = "Mouse Wheel / Q E  Focus     ESC  Exit"
	if vignette != null:
		vignette.visible = true
	set_mode_text("MICROSCOPE")
	set_objective_text("Gem Examination")
	if status_label != null:
		status_label.text = "Adjust focus"

func hide_microscope_ui() -> void:
	if microscope_panel != null:
		microscope_panel.visible = false
	if crosshair_root != null:
		crosshair_root.visible = true
	if hint_label != null:
		hint_label.text = "WASD  Move     Mouse  Look     E  Use"
	if vignette != null:
		vignette.visible = false
	set_mode_text("WALK")
	set_objective_text("Gem Lab")

func update_microscope_ui(focus_value: float, blur_amount: float, inclusions: Array[String], is_focused: bool) -> void:
	if focus_label == null:
		return

	var rounded_focus := roundi(focus_value)
	focus_label.text = "Focus  %d / 100" % rounded_focus
	if focus_bar != null:
		focus_bar.value = focus_value
	if blur_label != null:
		blur_label.text = "Image Blur  %.2f" % blur_amount

	if is_focused:
		var inclusion_text := "--"
		if not inclusions.is_empty():
			inclusion_text = ", ".join(inclusions)
		inclusion_label.text = "Inclusions  %s" % inclusion_text
		inclusion_label.add_theme_color_override("font_color", GOOD)
		status_label.text = "Focus locked"
		status_label.add_theme_color_override("font_color", GOOD)
	else:
		inclusion_label.text = "Inclusions  --"
		inclusion_label.add_theme_color_override("font_color", TEXT_SOFT)
		status_label.text = "Searching..."
		status_label.add_theme_color_override("font_color", WARN)

func show_uvbox_ui() -> void:
	if uvbox_panel != null:
		uvbox_panel.visible = true
	if crosshair_root != null:
		crosshair_root.visible = false
	if hint_label != null:
		hint_label.text = "1  Long Wave     2  Short Wave     3  Off     ESC  Exit"
	if vignette != null:
		vignette.visible = true
	set_mode_text("UV BOX")
	set_objective_text("UV Fluorescence")

func hide_uvbox_ui() -> void:
	if uvbox_panel != null:
		uvbox_panel.visible = false
	if crosshair_root != null:
		crosshair_root.visible = true
	if hint_label != null:
		hint_label.text = "WASD  Move     Mouse  Look     E  Use"
	if vignette != null:
		vignette.visible = false
	set_mode_text("WALK")
	set_objective_text("Gem Lab")

func update_uvbox_ui(mode_text: String, wavelength_text: String, color: Color) -> void:
	if uv_mode_label != null:
		uv_mode_label.text = "Lamp  %s" % mode_text
	if uv_wavelength_label != null:
		uv_wavelength_label.text = "Wavelength  %s" % wavelength_text
	if uv_status_label != null:
		uv_status_label.text = "Choose a UV wavelength" if mode_text == "Off" else "Observe fluorescence response"
	if uv_color_strip != null:
		uv_color_strip.color = color

func set_mode_text(text: String) -> void:
	if mode_label != null:
		mode_label.text = text

func set_objective_text(text: String) -> void:
	if objective_label != null:
		objective_label.text = text

func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.name = "GameHUD"
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hud_root)

func _build_vignette() -> void:
	vignette = ColorRect.new()
	vignette.name = "InstrumentVignette"
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0.0, 0.0, 0.0, 0.18)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.add_child(vignette)

func _build_top_left_status() -> void:
	var panel := PanelContainer.new()
	panel.name = "StatusPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 22
	panel.offset_top = 20
	panel.offset_right = 290
	panel.offset_bottom = 88
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, 8, Color(1, 1, 1, 0.08)))
	hud_root.add_child(panel)

	var margin := _margin(16, 10, 16, 10)
	panel.add_child(margin)

	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 2)
	margin.add_child(rows)

	objective_label = _label("Gem Lab", 18, TEXT_MAIN)
	objective_label.name = "ObjectiveLabel"
	rows.add_child(objective_label)

	mode_label = _label("WALK", 12, ACCENT)
	mode_label.name = "ModeLabel"
	rows.add_child(mode_label)

func _build_crosshair() -> void:
	crosshair_root = Control.new()
	crosshair_root.name = "Crosshair"
	crosshair_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_root.set_anchors_preset(Control.PRESET_CENTER)
	crosshair_root.offset_left = -10
	crosshair_root.offset_top = -10
	crosshair_root.offset_right = 10
	crosshair_root.offset_bottom = 10
	hud_root.add_child(crosshair_root)

	crosshair_dot = ColorRect.new()
	crosshair_dot.name = "Dot"
	crosshair_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_dot.color = Color(1.0, 0.94, 0.8, 0.92)
	crosshair_dot.anchor_left = 0.5
	crosshair_dot.anchor_top = 0.5
	crosshair_dot.anchor_right = 0.5
	crosshair_dot.anchor_bottom = 0.5
	crosshair_dot.offset_left = -2
	crosshair_dot.offset_top = -2
	crosshair_dot.offset_right = 2
	crosshair_dot.offset_bottom = 2
	crosshair_root.add_child(crosshair_dot)

func _build_prompt() -> void:
	prompt_panel = PanelContainer.new()
	prompt_panel.name = "InteractionPrompt"
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.anchor_left = 0.5
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.offset_left = -250
	prompt_panel.offset_top = -148
	prompt_panel.offset_right = 250
	prompt_panel.offset_bottom = -92
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG_STRONG, 8, ACCENT))
	hud_root.add_child(prompt_panel)

	var margin := _margin(20, 8, 20, 8)
	prompt_panel.add_child(margin)

	prompt_label = _label("", 22, TEXT_MAIN)
	prompt_label.name = "PromptLabel"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(prompt_label)

func _build_hint_bar() -> void:
	hint_label = _label("WASD  Move     Mouse  Look     E  Use", 14, TEXT_SOFT)
	hint_label.name = "HintLabel"
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.anchor_left = 0.0
	hint_label.anchor_top = 1.0
	hint_label.anchor_right = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_left = 0
	hint_label.offset_top = -46
	hint_label.offset_right = 0
	hint_label.offset_bottom = -20
	hud_root.add_child(hint_label)

func _build_microscope_panel() -> void:
	microscope_panel = PanelContainer.new()
	microscope_panel.name = "MicroscopePanel"
	microscope_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	microscope_panel.anchor_left = 1.0
	microscope_panel.anchor_top = 0.0
	microscope_panel.anchor_right = 1.0
	microscope_panel.anchor_bottom = 0.0
	microscope_panel.offset_left = -394
	microscope_panel.offset_top = 24
	microscope_panel.offset_right = -24
	microscope_panel.offset_bottom = 228
	microscope_panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, 8, Color(1, 1, 1, 0.1)))
	hud_root.add_child(microscope_panel)

	var margin := _margin(18, 16, 18, 16)
	microscope_panel.add_child(margin)

	var list := VBoxContainer.new()
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_theme_constant_override("separation", 8)
	margin.add_child(list)

	var title := _label("MICROSCOPE", 20, TEXT_MAIN)
	title.name = "MicroscopeTitle"
	list.add_child(title)

	focus_label = _label("Focus  0 / 100", 15, TEXT_MAIN)
	list.add_child(focus_label)

	focus_bar = ProgressBar.new()
	focus_bar.name = "FocusBar"
	focus_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_bar.min_value = 0
	focus_bar.max_value = 100
	focus_bar.value = 0
	focus_bar.show_percentage = false
	focus_bar.custom_minimum_size = Vector2(260, 10)
	focus_bar.add_theme_stylebox_override("background", _panel_style(Color(0.1, 0.09, 0.075, 0.9), 4, Color.TRANSPARENT))
	focus_bar.add_theme_stylebox_override("fill", _panel_style(ACCENT, 4, Color.TRANSPARENT))
	list.add_child(focus_bar)

	blur_label = _label("Image Blur  --", 14, TEXT_SOFT)
	inclusion_label = _label("Inclusions  --", 14, TEXT_SOFT)
	status_label = _label("Ready", 14, ACCENT)
	list.add_child(blur_label)
	list.add_child(inclusion_label)
	list.add_child(status_label)

func _build_uvbox_panel() -> void:
	uvbox_panel = PanelContainer.new()
	uvbox_panel.name = "UVBoxPanel"
	uvbox_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	uvbox_panel.anchor_left = 1.0
	uvbox_panel.anchor_top = 0.0
	uvbox_panel.anchor_right = 1.0
	uvbox_panel.anchor_bottom = 0.0
	uvbox_panel.offset_left = -394
	uvbox_panel.offset_top = 24
	uvbox_panel.offset_right = -24
	uvbox_panel.offset_bottom = 210
	uvbox_panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, 8, Color(1, 1, 1, 0.1)))
	hud_root.add_child(uvbox_panel)

	var margin := _margin(18, 16, 18, 16)
	uvbox_panel.add_child(margin)

	var list := VBoxContainer.new()
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_theme_constant_override("separation", 8)
	margin.add_child(list)

	var title := _label("UV LIGHT BOX", 20, TEXT_MAIN)
	list.add_child(title)

	uv_color_strip = ColorRect.new()
	uv_color_strip.name = "WaveColor"
	uv_color_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	uv_color_strip.color = Color(0.45, 0.22, 1.0, 1.0)
	uv_color_strip.custom_minimum_size = Vector2(260, 8)
	list.add_child(uv_color_strip)

	uv_mode_label = _label("Lamp  Long Wave", 15, TEXT_MAIN)
	uv_wavelength_label = _label("Wavelength  365 nm", 14, TEXT_SOFT)
	uv_status_label = _label("Observe fluorescence response", 14, ACCENT)
	list.add_child(uv_mode_label)
	list.add_child(uv_wavelength_label)
	list.add_child(uv_status_label)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

func _panel_style(bg_color: Color, radius: int, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style
