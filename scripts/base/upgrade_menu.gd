class_name UpgradeMenu
extends CanvasLayer

signal closed

const UPGRADES := [
	{
		"id": "max_hp",
		"name": "Fortitude",
		"desc": "Increase max health by 20",
		"cost": 2,
		"max_level": 5,
	},
	{
		"id": "damage",
		"name": "Sharpening",
		"desc": "Increase sword damage by 5",
		"cost": 3,
		"max_level": 5,
	},
	{
		"id": "roll_cooldown",
		"name": "Swiftness",
		"desc": "Reduce roll cooldown by 0.1s",
		"cost": 2,
		"max_level": 5,
	},
	{
		"id": "move_speed",
		"name": "Traveller",
		"desc": "Increase movement speed by 0.5",
		"cost": 2,
		"max_level": 3,
	},
]

@onready var upgrade_list: VBoxContainer = %UpgradeList
@onready var soul_label: Label = %SoulLabel
@onready var close_btn: Button = %CloseButton
@onready var overlay: ColorRect = %Overlay

func _ready() -> void:
	hide()
	close_btn.pressed.connect(_close)

func open() -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh()

func _close() -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	closed.emit()

func _refresh() -> void:
	soul_label.text = "Souls:  %d" % GameManager.souls
	soul_label.add_theme_font_size_override("font_size", 26)
	soul_label.add_theme_color_override("font_color", Color("#7ecfed"))

	for child in upgrade_list.get_children():
		child.queue_free()

	for upgrade in UPGRADES:
		var current_level: int = GameManager.unlocked_upgrades.count(upgrade["id"])
		var maxed: bool = current_level >= upgrade["max_level"]
		var can_afford: bool = GameManager.souls >= upgrade["cost"]

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 64)
		row.add_theme_constant_override("separation", 16)

		var sep := HSeparator.new()
		sep.add_theme_color_override("color", Color("#3d2e1e"))

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 4)

		var name_label := Label.new()
		name_label.text = upgrade["name"] + ("  [MAX]" if maxed else "  (Lv %d/%d)" % [current_level, upgrade["max_level"]])
		name_label.add_theme_font_size_override("font_size", 26)
		name_label.add_theme_color_override("font_color", Color("#ede0c8") if not maxed else Color("#4a4440"))

		var desc_label := Label.new()
		desc_label.text = upgrade["desc"]
		desc_label.add_theme_font_size_override("font_size", 20)
		desc_label.add_theme_color_override("font_color", Color("#8a7a62"))

		info.add_child(name_label)
		info.add_child(desc_label)

		var btn := Button.new()
		btn.text = "Buy (%d)" % upgrade["cost"] if not maxed else "Maxed"
		btn.disabled = maxed or not can_afford
		btn.custom_minimum_size = Vector2(140, 48)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_buy.bind(upgrade))

		var normal_box := StyleBoxFlat.new()
		normal_box.bg_color = Color("#1a0f0a")
		normal_box.border_width_left = 2
		normal_box.border_width_right = 2
		normal_box.border_width_top = 2
		normal_box.border_width_bottom = 2
		normal_box.border_color = Color("#a67c3d")
		normal_box.corner_radius_top_left = 3
		normal_box.corner_radius_top_right = 3
		normal_box.corner_radius_bottom_left = 3
		normal_box.corner_radius_bottom_right = 3
		normal_box.content_margin_left = 16
		normal_box.content_margin_right = 16
		normal_box.content_margin_top = 10
		normal_box.content_margin_bottom = 10

		var hover_box := StyleBoxFlat.new()
		hover_box.bg_color = Color("#2e1f12")
		hover_box.border_width_left = 2
		hover_box.border_width_right = 2
		hover_box.border_width_top = 2
		hover_box.border_width_bottom = 2
		hover_box.border_color = Color("#d4a455")
		hover_box.corner_radius_top_left = 3
		hover_box.corner_radius_top_right = 3
		hover_box.corner_radius_bottom_left = 3
		hover_box.corner_radius_bottom_right = 3
		hover_box.content_margin_left = 16
		hover_box.content_margin_right = 16
		hover_box.content_margin_top = 10
		hover_box.content_margin_bottom = 10

		var pressed_box := StyleBoxFlat.new()
		pressed_box.bg_color = Color("#0e0805")
		pressed_box.border_width_left = 2
		pressed_box.border_width_right = 2
		pressed_box.border_width_top = 2
		pressed_box.border_width_bottom = 2
		pressed_box.border_color = Color("#c9a84c")
		pressed_box.corner_radius_top_left = 3
		pressed_box.corner_radius_top_right = 3
		pressed_box.corner_radius_bottom_left = 3
		pressed_box.corner_radius_bottom_right = 3
		pressed_box.content_margin_left = 16
		pressed_box.content_margin_right = 16
		pressed_box.content_margin_top = 10
		pressed_box.content_margin_bottom = 10

		var disabled_box := StyleBoxFlat.new()
		disabled_box.bg_color = Color("#111111")
		disabled_box.border_width_left = 2
		disabled_box.border_width_right = 2
		disabled_box.border_width_top = 2
		disabled_box.border_width_bottom = 2
		disabled_box.border_color = Color("#2e2a26")
		disabled_box.corner_radius_top_left = 3
		disabled_box.corner_radius_top_right = 3
		disabled_box.corner_radius_bottom_left = 3
		disabled_box.corner_radius_bottom_right = 3
		disabled_box.content_margin_left = 16
		disabled_box.content_margin_right = 16
		disabled_box.content_margin_top = 10
		disabled_box.content_margin_bottom = 10

		btn.add_theme_stylebox_override("normal", normal_box)
		btn.add_theme_stylebox_override("hover", hover_box)
		btn.add_theme_stylebox_override("pressed", pressed_box)
		btn.add_theme_stylebox_override("disabled", disabled_box)
		btn.add_theme_color_override("font_color", Color("#c9a84c"))
		btn.add_theme_color_override("font_hover_color", Color("#e8d48a"))
		btn.add_theme_color_override("font_pressed_color", Color("#a67c3d"))
		btn.add_theme_color_override("font_disabled_color", Color("#3a3530"))

		btn.mouse_entered.connect(func():
			create_tween().tween_property(btn, "modulate", Color(1.1, 1.1, 1.0), 0.1))
		btn.mouse_exited.connect(func():
			create_tween().tween_property(btn, "modulate", Color.WHITE, 0.1))

		upgrade_list.add_child(sep)
		row.add_child(info)
		row.add_child(btn)
		upgrade_list.add_child(row)

func _buy(upgrade: Dictionary) -> void:
	if not GameManager.spend_souls(upgrade["cost"]):
		return
	GameManager.unlocked_upgrades.append(upgrade["id"])
	GameManager.apply_upgrade(upgrade["id"])
	GameManager.save()
	_refresh()
