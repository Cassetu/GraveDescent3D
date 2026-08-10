class_name ShopMenu
extends CanvasLayer

signal closed

const STAT_POOL := [
	{
		"id": "max_hp",
		"name": "Adrenaline",
		"desc": "+20 max HP (this run)",
		"cost": 20,
		"max_level": 3,
	},
	{
		"id": "damage",
		"name": "Battle Trance",
		"desc": "+5 damage (this run)",
		"cost": 25,
		"max_level": 3,
	},
	{
		"id": "max_stamina",
		"name": "Iron Lungs",
		"desc": "+20 max stamina (this run)",
		"cost": 20,
		"max_level": 3,
	},
	{
		"id": "stamina_regen",
		"name": "Second Wind",
		"desc": "+5 stamina regen/sec (this run)",
		"cost": 20,
		"max_level": 3,
	},
]

const CONSUMABLES := [
	{
		"id": "health_potion",
		"name": "Health Potion",
		"desc": "Restore 40 HP",
		"cost": 15,
		"icon": "res://assets/icons/health_potion.png",
	},
	{
		"id": "vigor_draught",
		"name": "Vigor Draught",
		"desc": "Restore 40 stamina",
		"cost": 10,
		"icon": "res://assets/icons/vigor_draught.png",
	},
]

const MAX_HELD: int = 3

var _offered_stats: Array = []

@onready var shop_list: VBoxContainer = %ShopList
@onready var shard_label: Label = %ShardLabel
@onready var close_btn: Button = %CloseButton
@onready var overlay: ColorRect = %Overlay

func _ready() -> void:
	hide()
	close_btn.pressed.connect(_close)
	var pool := STAT_POOL.duplicate()
	pool.shuffle()
	_offered_stats = pool.slice(0, 2)

func open() -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh()

func _close() -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	closed.emit()

func _refresh() -> void:
	shard_label.text = "Shards:  %d" % GameManager.shards
	shard_label.add_theme_font_size_override("font_size", 26)
	shard_label.add_theme_color_override("font_color", Color("#7ecfed"))

	for child in shop_list.get_children():
		child.queue_free()

	_add_header("Boons")
	for stat in _offered_stats:
		_add_stat_row(stat)

	_add_header("Supplies")
	for item in CONSUMABLES:
		_add_consumable_row(item)

func _add_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("#c9a84c"))
	shop_list.add_child(label)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color("#3d2e1e"))
	shop_list.add_child(sep)

func _add_stat_row(stat: Dictionary) -> void:
	var current_level: int = GameManager.run_upgrades.count(stat["id"])
	var maxed: bool = current_level >= stat["max_level"]
	var can_afford: bool = GameManager.shards >= stat["cost"]

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 64)
	row.add_theme_constant_override("separation", 16)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)

	var name_label := Label.new()
	name_label.text = stat["name"] + ("  [MAX]" if maxed else "  (Lv %d/%d)" % [current_level, stat["max_level"]])
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", Color("#ede0c8") if not maxed else Color("#4a4440"))

	var desc_label := Label.new()
	desc_label.text = stat["desc"]
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color("#8a7a62"))

	info.add_child(name_label)
	info.add_child(desc_label)

	var btn := Button.new()
	btn.text = "Buy (%d)" % stat["cost"] if not maxed else "Maxed"
	btn.disabled = maxed or not can_afford
	btn.custom_minimum_size = Vector2(140, 48)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_buy_stat.bind(stat))

	_style_button(btn)

	row.add_child(info)
	row.add_child(btn)
	shop_list.add_child(row)

func _add_consumable_row(item: Dictionary) -> void:
	var held: int = GameManager.get_consumable_count(item["id"])
	var maxed: bool = held >= MAX_HELD
	var can_afford: bool = GameManager.shards >= item["cost"]

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 64)
	row.add_theme_constant_override("separation", 16)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(item["icon"]):
		icon.texture = load(item["icon"])

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)

	var name_label := Label.new()
	name_label.text = item["name"] + ("  [%d/%d]" % [held, MAX_HELD])
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", Color("#ede0c8") if not maxed else Color("#4a4440"))

	var desc_label := Label.new()
	desc_label.text = item["desc"]
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color("#8a7a62"))

	info.add_child(name_label)
	info.add_child(desc_label)

	var btn := Button.new()
	btn.text = "Buy (%d)" % item["cost"] if not maxed else "Full"
	btn.disabled = maxed or not can_afford
	btn.custom_minimum_size = Vector2(140, 48)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_buy_consumable.bind(item))

	_style_button(btn)

	row.add_child(icon)
	row.add_child(info)
	row.add_child(btn)
	shop_list.add_child(row)

func _style_button(btn: Button) -> void:
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

func _buy_stat(stat: Dictionary) -> void:
	if not GameManager.spend_shards(stat["cost"]):
		return
	GameManager.apply_run_upgrade(stat["id"])
	GameManager.save()
	_refresh()

func _buy_consumable(item: Dictionary) -> void:
	if not GameManager.spend_shards(item["cost"]):
		return
	GameManager.add_consumable(item["id"])
	GameManager.save()
	_refresh()
