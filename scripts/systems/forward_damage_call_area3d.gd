extends Area3D

func take_damage(amount: int, dir: Vector3 = Vector3.ZERO, force: float = 0.0) -> void:
	if get_parent().has_method("take_damage"):
		get_parent().take_damage(amount, dir, force)
