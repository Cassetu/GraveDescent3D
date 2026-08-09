class_name HUD
extends CanvasLayer

@onready var red_bar: ProgressBar = %RedBar
@onready var white_bar: ProgressBar = %WhiteBar
@onready var damage_effect: DamageEffect = $DamageEffectLayer
@onready var souls_label: Label = %SoulsLabel
@onready var shards_label: Label = %ShardsLabel
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var hp_label: Label = %HpLabel

var _tween: Tween = null
var _white_delay_timer: float = 0.0
var _pending_white_shrink: bool = false
var _displayed_souls: int = 0
var _displayed_shards: int = 0
var _souls_tween: Tween = null
var _shards_tween: Tween = null
const WHITE_DELAY := 0.6
const WHITE_SHRINK_SPEED := 0.4

func _ready() -> void:
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		_set_bars(player.hp, player.max_hp)
	GameManager.souls_changed.connect(_on_souls_changed)
	GameManager.shards_changed.connect(_on_shards_changed)
	_on_souls_changed(GameManager.souls)
	_on_shards_changed(GameManager.shards)
	_style_currency_labels()

func _style_currency_labels() -> void:
	souls_label.add_theme_font_size_override("font_size", 46)
	souls_label.add_theme_color_override("font_color", Color("#7ecfed"))
	shards_label.add_theme_font_size_override("font_size", 46)
	shards_label.add_theme_color_override("font_color", Color("#e8c84a"))

func update_stamina(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current

func _on_souls_changed(amount: int) -> void:
	if _souls_tween:
		_souls_tween.kill()
	_souls_tween = create_tween()
	_souls_tween.tween_method(
		func(v: int): souls_label.text = "%d  Souls" % v,
		_displayed_souls, amount, 0.6
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_souls_tween.tween_callback(func(): _displayed_souls = amount)

func _on_shards_changed(amount: int) -> void:
	if _shards_tween:
		_shards_tween.kill()
	_shards_tween = create_tween()
	_shards_tween.tween_method(
		func(v: int): shards_label.text = "%d  Shards" % v,
		_displayed_shards, amount, 0.6
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_shards_tween.tween_callback(func(): _displayed_shards = amount)
func _process(delta: float) -> void:
	if _pending_white_shrink:
		_white_delay_timer -= delta
		if _white_delay_timer <= 0.0:
			_pending_white_shrink = false
			_shrink_white()

func take_damage_flash(new_hp: int, max_hp: int) -> void:
	red_bar.value = new_hp
	hp_label.text = "%d / %d" % [new_hp, max_hp]
	_pending_white_shrink = true
	_white_delay_timer = WHITE_DELAY
	if _tween:
		_tween.kill()
	var dynamic_threshold: float = clamp(35.0 / float(max_hp), 0.05, 0.25)
	damage_effect.update_hp(new_hp, max_hp, dynamic_threshold)

func _set_bars(hp: int, max_hp: int) -> void:
	red_bar.max_value = max_hp
	red_bar.value = hp
	white_bar.max_value = max_hp
	white_bar.value = hp
	hp_label.text = "%d / %d" % [hp, max_hp]

func _shrink_white() -> void:
	_tween = create_tween()
	_tween.tween_property(white_bar, "value", red_bar.value, WHITE_SHRINK_SPEED)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUINT)

func heal(new_hp: int, max_hp: int) -> void:
	if _tween:
		_tween.kill()
	red_bar.value = new_hp
	white_bar.value = new_hp
