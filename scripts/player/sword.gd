class_name Sword
extends Node3D

@export var damage: int = 15
@export var knockback_force: float = 7.0

@onready var shape_cast: ShapeCast3D = $ShapeCast3D

var _can_hit: bool = false
var _hit_this_swing: Array[Node] = []

func enable_hitbox() -> void:
	_can_hit = true
	_hit_this_swing.clear()

func disable_hitbox() -> void:
	_can_hit = false

func _physics_process(_delta: float) -> void:
	if not _can_hit:
		return
	if not shape_cast.is_colliding():
		return
	for i in shape_cast.get_collision_count():
		var hit := shape_cast.get_collider(i)
		if not hit is Enemy:
			continue
		if hit in _hit_this_swing:
			continue
		if not _has_line_of_sight(hit):
			continue
		var enemy := hit as Enemy
		var to_enemy := enemy.global_position - global_position
		to_enemy.y = 0.0
		var forward := -get_viewport().get_camera_3d().global_basis.z
		forward.y = 0.0
		var dot := forward.normalized().dot(to_enemy.normalized())
		if dot < 0.0:
			continue
		_hit_this_swing.append(hit)
		var dir: Vector3 = (enemy.global_position - global_position).normalized()
		dir.y = 0.0
		enemy.take_hit(damage, dir, knockback_force)
					
func _has_line_of_sight(target: Enemy) -> bool:
	var space := get_world_3d().direct_space_state
	var origin := global_position
	var destination := target.global_position + Vector3(0, 0.5, 0)
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [target.get_rid()]
	var result := space.intersect_ray(query)
	return result.is_empty()
