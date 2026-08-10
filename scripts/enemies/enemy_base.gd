class_name Enemy
extends CharacterBody3D

@export var max_hp: int = 30
@export var move_speed: float = 2.5
@export var attack_damage: int = 10
@export var attack_range: float = 1.4
@export var attack_cooldown: float = 1.5
@export var knockback_recovery: float = 4.0
@export var gravity: float = 20.0
@export var can_patrol: bool = true
@export var sight_range: float = 15.0
@export var patrol_radius: float = 6.0

var _patrol_timer: float = 0.0
var _is_patrolling: bool = false
enum State { IDLE, CHASE, ATTACK, STAGGERED, DEAD }

var hp: int
var state: State = State.IDLE
var _player: Player = null
var _attack_timer: float = 0.0
var _stagger_timer: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO

@export var turn_speed: float = 15.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	hp = max_hp
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	_process_state(delta)

	move_and_slide()

func _process_state(delta: float) -> void:
	match state:
		State.IDLE: _tick_idle(delta)
		State.CHASE: _tick_chase(delta)
		State.ATTACK: _tick_attack(delta)
		State.STAGGERED: _tick_stagger(delta)

func _tick_idle(delta: float) -> void:
	if _can_see_player():
		state = State.CHASE
		return

	if not can_patrol:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		return

	_patrol_timer -= delta
	
	if _patrol_timer <= 0.0:
		if _is_patrolling:
			_is_patrolling = false
			_patrol_timer = randf_range(2.0, 4.0)
		else:
			_is_patrolling = true
			_patrol_timer = randf_range(3.0, 6.0)
			_pick_random_patrol_point()

	if _is_patrolling:
		if nav_agent.is_navigation_finished():
			_is_patrolling = false
			_patrol_timer = randf_range(2.0, 4.0)
		else:
			var next := nav_agent.get_next_path_position()
			var dir := (next - global_position)
			dir.y = 0.0
			if dir.length() > 0.1:
				var target_rot := atan2(-dir.x, -dir.z)
				rotation.y = lerp_angle(rotation.y, target_rot, delta * turn_speed * 0.4)
				dir = dir.normalized()
				velocity.x = dir.x * (move_speed * 0.4)
				velocity.z = dir.z * (move_speed * 0.4)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)

func _tick_chase(delta: float) -> void:
	if not _player:
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if dist > 0.1:
		var target_rot := atan2(-to_player.x, -to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * turn_speed) # <--- USE IT HERE

	var forward := -global_basis.z
	forward.y = 0.0
	var dot_to_player := forward.normalized().dot(to_player.normalized())

	if dist <= attack_range and dot_to_player > 0.85:
		state = State.ATTACK
		return

	nav_agent.target_position = _get_flank_target()
	var next := nav_agent.get_next_path_position()
	var dir := (next - global_position)
	dir.y = 0.0

	var separation := Vector3.ZERO
	var neighbors := get_tree().get_nodes_in_group("enemy")
	for n in neighbors:
		if n != self and is_instance_valid(n):
			var d := global_position.distance_to(n.global_position)
			if d < 1.5 and d > 0.01:
				var push: Vector3 = (global_position - n.global_position).normalized()
				separation += push * (1.5 - d)

	if dir.length() > 0.1:
		dir = (dir.normalized() + separation * 2.5).normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
func _get_flank_target() -> Vector3:
	var squad: Array = []
	for n in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(n) and (n.state == State.CHASE or n.state == State.ATTACK):
			squad.append(n)
	squad.sort_custom(func(a, b): return a.get_instance_id() < b.get_instance_id())

	var slot := squad.find(self)
	if slot == -1 or squad.size()<= 1:
		return _player.global_position

	var angle := (TAU / squad.size()) * slot
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * (attack_range *0.9)
	return _player.global_position + offset
func _tick_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)

	if not _player:
		return

	_attack_timer -= delta

	if _attack_timer <= 0.0:
		var to_player := _player.global_position - global_position
		to_player.y = 0.0
		var dist := to_player.length()

		var forward := -global_basis.z
		forward.y = 0.0
		var dot_to_player := forward.normalized().dot(to_player.normalized())

		if dist <= attack_range and dot_to_player > 0.85:
			_do_attack()
			_attack_timer = attack_cooldown
		else:
			state = State.CHASE
func _on_moving() -> void:
	pass  # override in subclass

func _tick_stagger(delta: float) -> void:
	_stagger_timer -= delta
	_knockback_velocity = _knockback_velocity.lerp(Vector3.ZERO, knockback_recovery * delta)
	velocity.x = _knockback_velocity.x
	velocity.z = _knockback_velocity.z
	if _stagger_timer <= 0.0:
		state = State.CHASE

func _do_attack() -> void:
	if _player:
		var dir := (_player.global_position - global_position).normalized()
		_player.take_damage(attack_damage, dir)

func take_hit(damage: int, knockback_dir: Vector3, knockback_force: float = 6.0) -> void:
	if state == State.DEAD:
		return
	hp -= damage
	if hp <= 0:
		_die()
		return
	_knockback_velocity = knockback_dir * knockback_force
	_stagger_timer = 0.4
	state = State.STAGGERED

func _die() -> void:
	state = State.DEAD
	queue_free()

func _can_see_player() -> bool:
	if not _player:
		return false
	var to_player := _player.global_position - global_position
	if to_player.length() > sight_range:
		return false

	var space_state := get_world_3d().direct_space_state
	var start_pos := global_position + Vector3(0.0, 1.0, 0.0)
	var end_pos := _player.global_position + Vector3(0.0, 1.0, 0.0)

	var query := PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [get_rid()]
	query.collision_mask = 1

	var result := space_state.intersect_ray(query)
	if result and result.collider is Player:
		return true
	return false
func hear_noise(origin: Vector3) -> void:
	if state == State.CHASE or state == State.ATTACK:
		return
		
	nav_agent.target_position = origin
	_is_patrolling = true
	_patrol_timer = 6.0
	state = State.IDLE
func _pick_random_patrol_point() -> void:
	var random_x := randf_range(-1.0, 1.0)
	var random_z := randf_range(-1.0, 1.0)
	var random_offset := Vector3(random_x, 0.0, random_z).normalized() * randf_range(2.0, patrol_radius)
	nav_agent.target_position = global_position + random_offset
