extends Node3D

@export var max_hp: int = 1

func take_damage(amount: int, _dir: Vector3 = Vector3.ZERO, _force: float = 0.0) -> void:
	max_hp -= amount
	if max_hp <= 0:
		_destroy_prop()

func _destroy_prop() -> void:
	var fragments: PackedScene = load("res://scenes/particles/broken_particles.tscn")
	if fragments:
		var fx := fragments.instantiate()
		get_parent().add_child(fx)
		var hurtbox = get_node_or_null("Hurtbox")
		if hurtbox:
			fx.global_position = hurtbox.global_position
		else:
			fx.global_position = global_position
		if fx.has_method("restart"):
			fx.restart()
			
	queue_free()
