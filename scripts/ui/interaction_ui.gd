extends CanvasLayer

var _container: PanelContainer
var _key_label: Label
var _text_label: Label
var _tween: Tween

func _ready() -> void:
	_container = PanelContainer.new()
	_container.anchor_left = 0.5
	_container.anchor_right = 0.5
	_container.anchor_top = 0.82
	_container.anchor_bottom = 0.82
	_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#140e0a")
	panel_style.bg_color.a = 0.82
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color("#a67c3d")
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	_container.add_theme_stylebox_override("panel", panel_style)
	_container.modulate.a = 0.0

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var key_panel := PanelContainer.new()
	key_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = Color("#a67c3d")
	key_style.corner_radius_top_left = 3
	key_style.corner_radius_top_right = 3
	key_style.corner_radius_bottom_left = 3
	key_style.corner_radius_bottom_right = 3
	key_style.content_margin_left = 10
	key_style.content_margin_right = 10
	key_style.content_margin_top = 2
	key_style.content_margin_bottom = 2
	key_panel.add_theme_stylebox_override("panel", key_style)

	_key_label = Label.new()
	_key_label.text = "E"
	_key_label.add_theme_font_size_override("font_size", 26)
	_key_label.add_theme_color_override("font_color", Color("#140e0a"))
	_key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_panel.add_child(_key_label)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 26)
	_text_label.add_theme_color_override("font_color", Color("#ede0c8"))
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	hbox.add_child(key_panel)
	hbox.add_child(_text_label)
	_container.add_child(hbox)
	add_child(_container)

func update(text: String) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if text == "":
		_tween.tween_property(_container, "modulate:a", 0.0, 0.15)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_SINE)
	else:
		_text_label.text = text.trim_prefix("[E] ")
		_tween.tween_property(_container, "modulate:a", 1.0, 0.2)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_SINE)
