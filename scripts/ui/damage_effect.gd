class_name DamageEffect
extends CanvasLayer

@onready var vignette: ColorRect = %Vignette
@onready var blur_rect: ColorRect = %BlurRect

var _hp_percent: float = 1.0
var _pulse_timer: float = 0.0
var _pulse_interval: float = 999.0
var _is_pulsing: bool = false
var _tween: Tween = null

const THRESHOLD := 0.25

func _ready() -> void:
	vignette.modulate.a = 0.0
	blur_rect.modulate.a = 1.0
	var blur_material: ShaderMaterial = blur_rect.material as ShaderMaterial
	blur_material.set_shader_parameter("blur_amount", 0.0)

func update_hp(hp: int, max_hp: int, threshold: float = 0.25) -> void:
	_hp_percent = float(hp) / float(max_hp)
	if _hp_percent > threshold:
		_stop()
		return
	var vignette_alpha: float = lerp(0.7, 0.15, _hp_percent / threshold)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(vignette, "modulate:a", vignette_alpha, 0.8)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_pulse_interval = lerp(0.6, 2.5, _hp_percent / threshold)
	if not _is_pulsing:
		_is_pulsing = true
		_pulse_blur()

func _process(delta: float) -> void:
	if not _is_pulsing:
		return
	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		_pulse_blur()

func _pulse_blur() -> void:
	_pulse_timer = _pulse_interval
	var max_blur: float = lerp(8.0, 2.0, _hp_percent / THRESHOLD)
	var min_blur: float = 0.5
	var blur_material: ShaderMaterial = blur_rect.material as ShaderMaterial

	var blur_tween := create_tween()
	blur_tween.tween_method(
		func(v: float): blur_material.set_shader_parameter("blur_amount", v),
		min_blur, max_blur, 0.6
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	blur_tween.tween_method(
		func(v: float): blur_material.set_shader_parameter("blur_amount", v),
		max_blur, min_blur, 0.9
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _get_max_alpha() -> float:
	return lerp(0.9, 0.35, _hp_percent / THRESHOLD)

func _stop() -> void:
	_is_pulsing = false
	_pulse_timer = 0.0
	if _tween:
		_tween.kill()
	var blur_material: ShaderMaterial = blur_rect.material as ShaderMaterial
	var t := create_tween()
	t.tween_property(vignette, "modulate:a", 0.0, 1.0)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_method(
		func(v: float): blur_material.set_shader_parameter("blur_amount", v),
		blur_material.get_shader_parameter("blur_amount"), 0.0, 1.0
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
