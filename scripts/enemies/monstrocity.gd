class_name Monstrocity
extends Enemy

var anim_controller: MonstrocityAnim = null
var _ability_timer: float = 3.0
var soul_drop = 25
var shard_drop = 100
func _ready() -> void:
	max_hp = 600
	move_speed = 5.0
	attack_damage = 15
	hp = max_hp
	
	
	super._ready()
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player") as Player
	anim_controller = _find_anim_controller(self)
	if anim_controller:
		anim_controller.idle()

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_process_hit_timings(delta)

	if not is_on_floor():
		velocity.y -= gravity * delta

	match state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if _player and global_position.distance_to(_player.global_position) < 15.0:
				state = State.CHASE
			_handle_locomotion_animations()
				
		State.CHASE:
			_ability_timer -= delta
			if _ability_timer <= 0:
				_choose_attack()
				return
				
			if _player:
				var to_player := (_player.global_position - global_position)
				to_player.y = 0.0
				if to_player.length() > 1.5:
					velocity.x = to_player.normalized().x * move_speed
					velocity.z = to_player.normalized().z * move_speed
					var target_angle := atan2(-to_player.x, -to_player.z)
					rotation.y = lerp_angle(rotation.y, target_angle, delta * 4.0)
				else:
					velocity.x = 0.0
					velocity.z = 0.0
			
			_handle_locomotion_animations()
						
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0, delta * 10.0)
			velocity.z = move_toward(velocity.z, 0, delta * 10.0)
				
		State.STAGGERED:
			velocity.x = move_toward(velocity.x, 0, delta * 10.0)
			velocity.z = move_toward(velocity.z, 0, delta * 10.0)

	move_and_slide()

func _handle_locomotion_animations() -> void:
	if not anim_controller:
		return
		
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	
	if horizontal_speed > 3.5:
		if anim_controller._current != "run_battle_1":
			anim_controller.run()
	elif horizontal_speed > 0.1:
		if anim_controller._current != "walk_normal_1":
			anim_controller.walk()
	else:
		if anim_controller._current != "idle_battle_1":
			anim_controller.idle()

func _process_hit_timings(delta: float) -> void:
	if state != State.ATTACK or not anim_controller:
		return
		
	if anim_controller.anim_player and anim_controller.anim_player.is_playing():
		var pos = anim_controller.anim_player.current_animation_position
		
		if anim_controller._current == "att_battle_1_01":
			if abs(pos - 6.5) < delta: _perform_hit_check(3.5, 0.5, 1.0)
			if abs(pos - 7.65) < delta: _perform_hit_check(3.5, 0.5, 0.5)
			
		elif anim_controller._current == "att_battle_6_01":
			if abs(pos - 29.0) < delta: _perform_hit_check(3.5, 0.5, 1.1)

func _choose_attack() -> void:
	state = State.ATTACK
	var chance := randf()
	
	if chance < 0.50:
		anim_controller.claw(func(): _on_attack_complete())
	else:
		anim_controller.claw_2(func(): _on_attack_complete())

func _on_attack_complete() -> void:
	_ability_timer = randf_range(1.5, 3.0)
	state = State.CHASE

func _perform_hit_check(reach: float, arc_dot: float, dmg_mult: float) -> void:
	if not _player: return
	var to_p := _player.global_position - global_position
	if to_p.length() <= reach:
		var forward := -global_transform.basis.z.normalized()
		if forward.dot(to_p.normalized()) >= arc_dot:
			if _player.has_method("take_damage"):
				_player.take_damage(int(attack_damage * dmg_mult), forward)

func take_hit(amount: int, knockback_dir: Vector3 = Vector3.ZERO, knockback_force: float = 0.0) -> void:
	if state == State.DEAD: return
	super.take_hit(amount, knockback_dir, knockback_force)
	if hp <= 0:
		_die()

func _die() -> void:
	state = State.DEAD
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	if anim_controller:
		anim_controller.death()
		
	GameManager.add_souls(soul_drop)
	GameManager.add_shards(shard_drop)
		
	await get_tree().create_timer(10.0).timeout
	queue_free()

func _find_anim_controller(node: Node) -> MonstrocityAnim:
	for child in node.get_children():
		if child is MonstrocityAnim:
			return child
		var found := _find_anim_controller(child)
		if found:
			return found
	return null
