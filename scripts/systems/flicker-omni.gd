extends OmniLight3D

@export var base_energy: float = 8.0
@export var flicker_amount: float = 0.6
@export var flicker_speed: float = 1.0

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta * flicker_speed
	var n1 = sin(time * 7.3) * 0.4
	var n2 = sin(time * 13.7 + 1.2) * 0.3
	var n3 = sin(time * 3.1 + 2.5) * 0.3
	var noise = (n1 + n2 + n3) * flicker_amount
	light_energy = max(0.0, base_energy + noise)
