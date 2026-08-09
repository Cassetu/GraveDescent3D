class_name Chaos
extends Enemy

enum ChaosState { IDLE, WALKING, ABILITY, STAGGERED, DEAD }

@export var soul_drop: int = 15
@export var shard_drop: int = 60
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var flesh_sfx: AudioStreamPlayer3D = $FleshSFX
@onready var roar_sfx: AudioStreamPlayer3D = $RoarSFX
@onready var thud_sfx: AudioStreamPlayer3D = $ThudSFX
@onready var beam_sfx: AudioStreamPlayer3D = $BeamSFX
@onready var walk_sfx: AudioStreamPlayer3D = $WalkSFX
@onready var blood_particles: GPUParticles3D = $BloodParticles
var _footstep_timer: float = 0.0

#adjust
var walk_step_interval: float = 0.5
var strafe_step_interval: float = 0.6

var _current_beam_length: float = 0.0
var anim_controller: ChaosAnim = null
var chaos_state: ChaosState = ChaosState.IDLE
var _is_flying_smash: bool = false
var _smash_target_vel: Vector3 = Vector3.ZERO
var _phase: int = 1
var _ability_timer: float = 2.0
var _is_doing_ability: bool = false
var _summoned_this_phase: bool = false
var _still_timer: float = 0.0
var _strafe_timer: float = randf_range(4.0, 7.0)
var _strafe_active: bool = false
var _strafe_sign: int = 1
var _knockback_vel: Vector3 = Vector3.ZERO
var _stagger_t: float = 0.0
var _is_beaming: bool = false
var _beam_damage_timer: float = 0.0
var _beam_mesh_root: Node3D = null
var _beam_aim_dir: Vector3 = Vector3.FORWARD
var _spawned_minions: Array = []
var is_in_cutscene: bool = false

const MELEE_RANGE := 5.5
const PUNCH_OUT_RANGE := 7.0
const BEAM_RANGE := 50.0
const GRAB_STILL_TIME := 1.8
const COOLDOWN_P1 := 3.5
const COOLDOWN_P2 := 2.5
const COOLDOWN_P3 := 1.8

func _ready() -> void:
	print("[CHAOS] _ready start")
	max_hp = 600
	move_speed = 3.5
	attack_damage = 18
	can_patrol = false
	attack_range = 99999.0
	attack_cooldown = 99999.0
	hp = max_hp
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player") as Player
	print("[CHAOS] player found: ", _player != null)
	anim_controller = _find_anim_controller(self)
	print("[CHAOS] anim_controller found: ", anim_controller != null)
	if anim_controller:
		anim_controller.idle()
		print("[CHAOS] playing idle")
	add_child(music_player)
	music_player.stream = load("res://assets/audio/music/boss_1/phase_1.mp3")
	music_player.volume_db = -17
	#music_player.bus = "Music"
	if music_player.stream:
		music_player.play()
		print("[CHAOS] Boss music started looping")

func _process_state(delta: float) -> void:
	if is_in_cutscene:
		velocity = Vector3.ZERO
		return
		
	if chaos_state == ChaosState.WALKING and velocity.length() > 0.1:
		_footstep_timer += delta
		var current_interval := strafe_step_interval if _strafe_active else walk_step_interval
		
		if _footstep_timer >= current_interval:
			_footstep_timer = 0.0
			if walk_sfx:
				walk_sfx.pitch_scale = randf_range(0.85, 1.15)
				walk_sfx.play()
	else:
		_footstep_timer = 0.0
		
	match chaos_state:
		ChaosState.IDLE: _do_idle(delta)
		ChaosState.WALKING: _do_walking(delta)
		ChaosState.ABILITY:
			if _is_flying_smash:
				if is_on_wall(): _smash_target_vel = Vector3.ZERO
				velocity.x = _smash_target_vel.x
				velocity.z = _smash_target_vel.z
			else:
				velocity.x = 0.0
				velocity.z = 0.0
			if _is_beaming: _process_beam(delta)
		ChaosState.STAGGERED: _do_stagger(delta)
		ChaosState.DEAD:
			velocity.x = 0.0
			velocity.z = 0.0

func _do_idle(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if not _player:
		return
	if _flat_dist() < 16.0:
		print("[CHAOS] idle -> walking")
		_enter_walking()

func _do_walking(delta: float) -> void:
	if not _player:
		return

	_ability_timer -= delta

	if _ability_timer <= 0.0 and not _is_doing_ability:
		_choose_ability()
		return

	_still_timer = _still_timer + delta if _player.velocity.length() < 0.5 else 0.0
	_strafe_timer -= delta

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var movement_dir := Vector3.ZERO

	if nav_agent:
		nav_agent.target_position = _player.global_position
		var next_pos := nav_agent.get_next_path_position()
		var next_dir := (next_pos - global_position)
		next_dir.y = 0.0
		
		if next_dir.length() > 0.1:
			movement_dir = next_dir.normalized()
		else:
			movement_dir = to_player.normalized() if to_player.length() > 0.1 else Vector3.ZERO
	else:
		movement_dir = to_player.normalized() if to_player.length() > 0.1 else Vector3.ZERO

	if _strafe_active:
		var right := Vector3(to_player.z, 0.0, -to_player.x).normalized()
		movement_dir = (movement_dir + right * float(_strafe_sign) * 1.5).normalized()

	velocity.x = movement_dir.x * move_speed
	velocity.z = movement_dir.z * move_speed

	if to_player.length() > 0.1:
		var base_angle := atan2(-to_player.x, -to_player.z)
		var turn_speed := 2.0
		rotation.y = lerp_angle(rotation.y, base_angle, delta * turn_speed)

	if movement_dir.length() > 0.1:
		var space_state := get_world_3d().direct_space_state
		var ray_start := global_position + Vector3(0.0, 1.0, 0.0)
		var ray_end := ray_start + movement_dir * 2.0
		var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.exclude = [get_rid()]
		query.collision_mask = 1
		
		var result := space_state.intersect_ray(query)
		if result and result.collider.has_method("take_damage") and not (result.collider is Player):
			velocity = Vector3.ZERO
			if randf() > 0.5:
				_do_punch_close()
			else:
				_do_punch_out()
			return

	if _strafe_timer <= 0.0:
		_strafe_timer = randf_range(3.0, 6.0)
		_strafe_sign = 1 if randf() > 0.5 else -1
		_strafe_active = true

		if anim_controller:
			if _strafe_sign == 1:
				anim_controller.strafe_right()
			else:
				anim_controller.strafe_left()

		await get_tree().create_timer(0.7).timeout
		
		_strafe_active = false
		if chaos_state == ChaosState.WALKING and anim_controller:
			anim_controller.walk()

func _do_stagger(delta: float) -> void:
	_stagger_t -= delta
	_knockback_vel = _knockback_vel.lerp(Vector3.ZERO, knockback_recovery * delta)
	velocity.x = _knockback_vel.x
	velocity.z = _knockback_vel.z
	if _stagger_t <= 0.0:
		print("[CHAOS] stagger ended -> walking")
		_enter_walking()

func _enter_walking() -> void:
	print("[CHAOS] _enter_walking")
	chaos_state = ChaosState.WALKING
	state = State.CHASE
	if anim_controller:
		anim_controller.walk()

func _flat_dist() -> float:
	if not _player:
		return 999.0
	return Vector2(global_position.x, global_position.z).distance_to(
		Vector2(_player.global_position.x, _player.global_position.z)
	)

func _update_phase() -> void:
	var pct := float(hp) / float(max_hp)
	var new_phase := 1
	if pct < 0.7:
		new_phase = 2
	if pct < 0.45:
		new_phase = 3
	if new_phase != _phase:
		print("[CHAOS] PHASE CHANGE ", _phase, " -> ", new_phase, " | hp: ", hp, "/", max_hp)
		_phase = new_phase
		_summoned_this_phase = false
		match _phase:
			2:
				move_speed = 4.5
			3:
				move_speed = 5.5
		if not _is_doing_ability:
			_begin_ability()
			if anim_controller:
				roar_sfx.pitch_scale = randf_range(0.9, 1.1)
				roar_sfx.play()
				
				anim_controller.roar(func():
					print("[CHAOS] phase roar finished")
					_end_ability(1.0)
				)
		else:
			print("[CHAOS] phase changed mid-ability, skipping roar")

func _choose_ability() -> void:
	var dist := _flat_dist()
	print("[CHAOS] _choose_ability | phase: ", _phase, " | dist: ", dist, " | still_timer: ", _still_timer)
	match _phase:
		1:
			if dist <= MELEE_RANGE:
				print("[CHAOS] chose punch_close")
				_do_punch_close()
			else:
				print("[CHAOS] out of range in p1, resetting timer short")
				_ability_timer = 0.8
		2:
			if dist <= MELEE_RANGE:
				if _still_timer >= GRAB_STILL_TIME:
					print("[CHAOS] chose grab")
					_do_grab()
				else:
					print("[CHAOS] chose punch_close p2")
					_do_punch_close()
			elif dist <= PUNCH_OUT_RANGE:
				print("[CHAOS] chose punch_out")
				_do_punch_out()
			else:
				print("[CHAOS] chose flying_smash")
				_do_flying_smash()
		3:
			if not _summoned_this_phase:
				print("[CHAOS] chose summon")
				_do_summon()
			elif dist >= BEAM_RANGE * 0.5:
				print("[CHAOS] chose beam")
				_do_fly_summon_beam()
			elif dist <= MELEE_RANGE:
				print("[CHAOS] chose punch_close p3")
				_do_punch_close()
			else:
				print("[CHAOS] chose flying_smash p3")
				_do_flying_smash()

func _begin_ability() -> void:
	print("[CHAOS] _begin_ability | was_doing: ", _is_doing_ability)
	_is_doing_ability = true
	chaos_state = ChaosState.ABILITY
	velocity = Vector3.ZERO

func _end_ability(cooldown: float = -1.0) -> void:
	var cd := cooldown if cooldown >= 0.0 else _phase_cooldown()
	_is_doing_ability = false
	_ability_timer = cd
	
	if chaos_state != ChaosState.DEAD:
		_enter_walking()

func _phase_cooldown() -> float:
	match _phase:
		1: return COOLDOWN_P1
		2: return COOLDOWN_P2
		3: return COOLDOWN_P3
	return COOLDOWN_P1

func _do_punch_close() -> void:
	_begin_ability()
	print("[CHAOS] punch_close started")
	_punch_close_hit_check()
	if anim_controller:
		anim_controller.punch_close(func():
			_end_ability(0.4)
		)

func _do_punch_out() -> void:
	_begin_ability()
	print("[CHAOS] punch_out started")
	_punch_out_hit_check()
	if anim_controller:
		anim_controller.punch_out(func():
			_end_ability(0.6)
		)

func _punch_close_hit_check() -> void:
	await get_tree().create_timer(0.71).timeout
	if chaos_state == ChaosState.DEAD or not _player:
		return

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	
	var punch_reach := 3
	
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 1.6, punch_reach)
	query.shape = box
	
	var forward_offset := -global_basis.z.normalized() * (punch_reach * 0.5)
	var query_transform := global_transform
	query_transform.origin += forward_offset + Vector3(0.0, 1.2, 0.0)
	query.transform = query_transform
	query.collide_with_bodies = true
	query.exclude = [get_rid()]

	var intersections := space_state.intersect_shape(query)
	for result in intersections:
		if result.collider.has_method("take_damage") and not result.collider == self:
			var to_target: Vector3 = (result.collider.global_position - global_position).normalized()
			
			if result.collider is Player:
				_player.take_damage(attack_damage, to_target, 9.0)
				_trigger_directional_blood(result.metadata if "metadata" in result else _player.global_position)
				return
			else:
				result.collider.take_damage(1, to_target, 2.0)
			return
			
	print("[CHAOS] punch_close SHAPE MISS")

func _punch_out_hit_check() -> void:
	await get_tree().create_timer(1.0).timeout
	if chaos_state == ChaosState.DEAD or not _player:
		return

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	
	var punch_reach := 3
	
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 1.6, punch_reach)
	query.shape = box
	
	var forward_offset := -global_basis.z.normalized() * (punch_reach * 0.5)
	var query_transform := global_transform
	query_transform.origin += forward_offset + Vector3(0.0, 1.2, 0.0)
	query.transform = query_transform
	query.collide_with_bodies = true
	query.exclude = [get_rid()]

	var intersections := space_state.intersect_shape(query)
	for result in intersections:
		if result.collider.has_method("take_damage") and not result.collider == self:
			var to_target: Vector3 = (result.collider.global_position - global_position).normalized()
			
			if result.collider is Player:
				_player.take_damage(attack_damage, to_target, 9.0)
				_trigger_directional_blood(result.metadata if "metadata" in result else _player.global_position)
				return
			else:
				result.collider.take_damage(1, to_target, 2.0)
			
	print("[CHAOS] punch_out SHAPE MISS")

func _trigger_directional_blood(hit_position: Vector3) -> void:
	if not blood_particles:
		return
		
	blood_particles.global_position = hit_position
	
	var punch_dir := -global_basis.z.normalized()
	if punch_dir.cross(Vector3.UP).length() > 0.001:
		blood_particles.look_at(hit_position + punch_dir, Vector3.UP)
		
	blood_particles.restart()

func _do_grab() -> void:
	_still_timer = 0.0
	_begin_ability()
	print("[CHAOS] grab started")
	if anim_controller:
		anim_controller.grab(func():
			print("[CHAOS] grab anim done")
			await get_tree().create_timer(0.45).timeout
			if chaos_state == ChaosState.DEAD or not _player:
				return
				
			var to_player := _player.global_position - global_position
			to_player.y = 0.0
			var dist := to_player.length()
			
			var forward := -global_basis.z
			forward.y = 0.0
			forward = forward.normalized()
			
			var dot := 0.0
			if dist > 0.0:
				dot = forward.dot(to_player.normalized())
				
			if dist <= MELEE_RANGE and dot >= 0.4:
				_player.take_damage(int(attack_damage * 2.0), Vector3.ZERO, 0.0, 0.6)
				print("[CHAOS] grab HIT")
			else:
				print("[CHAOS] grab MISS")
			_end_ability()
		)

func _do_flying_smash() -> void:
	var target := _player.global_position if _player else global_position
	_begin_ability()
	print("[CHAOS] flying_smash started, target: ", target)

	var look_target := target
	look_target.y = global_position.y
	if look_target.distance_to(global_position) > 0.1:
		look_at(look_target, Vector3.UP)

	_flying_smash_sequence(target)

	if anim_controller:
		anim_controller.flying_smash(func():
			print("[CHAOS] flying_smash anim fully done")
			_is_flying_smash = false
			_end_ability(2.0)
		)

func _flying_smash_sequence(target: Vector3) -> void:
	await get_tree().create_timer(0.8).timeout
	if chaos_state == ChaosState.DEAD or chaos_state == ChaosState.STAGGERED:
		return

	var start_pos := global_position
	var to_target := target - start_pos
	to_target.y = 0.0

	var safe_dist := to_target
	if to_target.length() > 1.5:
		safe_dist = to_target - to_target.normalized() * 1.5

	var travel_time := 0.6
	_smash_target_vel = safe_dist / travel_time

	velocity.y = (gravity * travel_time) / 2.0 + 2.0
	_is_flying_smash = true

	for minion in _spawned_minions:
		if is_instance_valid(minion):
			add_collision_exception_with(minion)

	await get_tree().create_timer(0.35).timeout
	thud_sfx.pitch_scale = randf_range(0.9, 1.1)
	thud_sfx.play()

	await get_tree().create_timer(travel_time - 0.35).timeout
	_is_flying_smash = false

	for minion in _spawned_minions:
		if is_instance_valid(minion):
			remove_collision_exception_with(minion)

	if chaos_state == ChaosState.DEAD or chaos_state == ChaosState.STAGGERED:
		return

	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y = -25.0

	await get_tree().create_timer(0.1).timeout
	if chaos_state == ChaosState.DEAD or chaos_state == ChaosState.STAGGERED:
		return

	
	if _player and _player.has_method("apply_shake"):
		_player.apply_shake(0.7, 5.0)
	elif _player and _player.get_node_or_null("Camera3D"):
		var cam = _player.get_node("Camera3D")
		if cam.has_method("apply_shake"):
			cam.apply_shake(0.7, 5.0)

	var blast_radius := 2.5
	_spawn_floor_crater(global_position, blast_radius)

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	
	var blast_sphere := SphereShape3D.new()
	blast_sphere.radius = blast_radius
	query.shape = blast_sphere
	
	var query_transform := global_transform
	query_transform.origin += Vector3(0.0, 0.5, 0.0)
	query.transform = query_transform
	query.collide_with_bodies = true
	query.exclude = [get_rid()]

	var intersections := space_state.intersect_shape(query)
	for result in intersections:
		if result.collider.has_method("take_damage") and not result.collider == self:
			var blast_center := global_position + Vector3(0.0, 0.2, 0.0)
			var knockback_dir: Vector3 = (result.collider.global_position - blast_center).normalized()
			
			if result.collider is Player:
				knockback_dir.y += 0.4
				_player.take_damage(int(attack_damage * 1.4), knockback_dir.normalized(), 28.0)
				_trigger_directional_blood(_player.global_position)
			else:
				result.collider.take_damage(1, knockback_dir, 5.0)
			return
	
func _do_summon() -> void:
	_summoned_this_phase = true
	_begin_ability()
	if anim_controller:
		anim_controller.summon(func():
			if chaos_state == ChaosState.DEAD:
				return
			for i in 4:
				var s: PackedScene = load("res://scenes/skeleton_glad.tscn")
				if s:
					var skelly := s.instantiate()
					skelly.drops_loot = false
					get_parent().add_child(skelly)
					skelly.global_position = global_position + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
					_spawned_minions.append(skelly)
			
			_is_doing_ability = false
			_ability_timer = 0.5
			_enter_walking()
			
			await get_tree().create_timer(0.5).timeout
			if chaos_state == ChaosState.WALKING and not _is_doing_ability:
				_do_fly_summon_beam()
		)

func _do_fly_summon_beam() -> void:
	_begin_ability()
	print("[CHAOS] beam windup started")

	if _player:
		var look_target := _player.global_position
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)
		
		var start_pos := global_position + Vector3(0.0, 3.5, 0.0)
		var player_head := _player.global_position + Vector3(0.0, 1.7, 0.0)
		_beam_aim_dir = (player_head - start_pos).normalized()
		print("[BEAM DEBUG] Start Pos: ", start_pos, " | Target Head Pos: ", player_head, " | Initial Aim Dir: ", _beam_aim_dir)

	if anim_controller:
		anim_controller.fly_summon_beam(func():
			print("[CHAOS] beam anim fully done")
			_stop_sustained_beam()
			_end_ability()
		)

	await get_tree().create_timer(2.0).timeout
	if chaos_state == ChaosState.DEAD or chaos_state == ChaosState.STAGGERED:
		return
	_start_sustained_beam()

func _start_sustained_beam() -> void:
	print("[CHAOS] beam firing!")
	_is_beaming = true
	_beam_damage_timer = 0.0

	if beam_sfx:
		beam_sfx.volume_db = 0.0
		beam_sfx.play()

	_beam_mesh_root = Node3D.new()
	get_parent().add_child(_beam_mesh_root)
	_beam_mesh_root.global_position = global_position + Vector3(0.0, 3.5, 0.0)

	var inner := MeshInstance3D.new()
	var inner_box := BoxMesh.new()
	inner_box.size = Vector3(0.2, 0.2, 1.0)
	inner.mesh = inner_box
	var inner_mat := StandardMaterial3D.new()
	inner_mat.albedo_color = Color(0.8, 0.3, 1.0, 1.0)
	inner_mat.emission_enabled = true
	inner_mat.emission = Color(0.9, 0.2, 1.0)
	inner_mat.emission_energy_multiplier = 10.0
	inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	inner.set_surface_override_material(0, inner_mat)
	inner.name = "Inner"
	_beam_mesh_root.add_child(inner)

	var mid := MeshInstance3D.new()
	var mid_box := BoxMesh.new()
	mid_box.size = Vector3(0.4, 0.4, 1.0)
	mid.mesh = mid_box
	var mid_mat := StandardMaterial3D.new()
	mid_mat.albedo_color = Color(0.6, 0.0, 1.0, 0.45)
	mid_mat.emission_enabled = true
	mid_mat.emission = Color(0.7, 0.0, 1.0)
	mid_mat.emission_energy_multiplier = 5.0
	mid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mid_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mid.set_surface_override_material(0, mid_mat)
	mid.name = "Mid"
	_beam_mesh_root.add_child(mid)

	var outer := MeshInstance3D.new()
	var outer_box := BoxMesh.new()
	outer_box.size = Vector3(0.75, 0.75, 1.0)
	outer.mesh = outer_box
	var outer_mat := StandardMaterial3D.new()
	outer_mat.albedo_color = Color(0.4, 0.0, 0.8, 0.15)
	outer_mat.emission_enabled = true
	outer_mat.emission = Color(0.5, 0.0, 0.9)
	outer_mat.emission_energy_multiplier = 2.0
	outer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outer_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	outer.set_surface_override_material(0, outer_mat)
	outer.name = "Outer"
	_beam_mesh_root.add_child(outer)

	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.1, 1.0)
	light.light_energy = 5.0
	light.omni_range = 7.0
	light.omni_attenuation = 1.5
	light.name = "BeamLight"
	_beam_mesh_root.add_child(light)

func _process_beam(delta: float) -> void:
	if not _beam_mesh_root:
		return

	var start_pos := global_position + Vector3(0.0, 3.5, 0.0)
	_beam_mesh_root.global_position = start_pos
	
	var hit_player := false
	var target_distance := BEAM_RANGE

	if _player:
		var player_head := _player.global_position + Vector3(0.0, 0.6, 0.0)
		var target_dir := (player_head - start_pos).normalized()
		_beam_aim_dir = _beam_aim_dir.lerp(target_dir, delta * 3.0).normalized()
		
		var body_target := start_pos + _beam_aim_dir * 5.0
		body_target.y = global_position.y
		if body_target.distance_to(global_position) > 0.1:
			look_at(body_target, Vector3.UP)
			
		var beam_target := start_pos + _beam_aim_dir * 5.0
		_beam_mesh_root.look_at(beam_target, Vector3.UP)

	var space_state := get_world_3d().direct_space_state
	var end_pos := start_pos + _beam_aim_dir * BEAM_RANGE
	var query := PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [get_rid()]
	query.collision_mask = 1

	var result := space_state.intersect_ray(query)

	if result:
		target_distance = start_pos.distance_to(result.position)
		if result.collider is Player:
			hit_player = true

	_current_beam_length = move_toward(_current_beam_length, target_distance, delta * 30.0)

	for child in _beam_mesh_root.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			child.mesh.size.z = _current_beam_length
			child.position.z = -_current_beam_length * 0.5

	var beam_light := _beam_mesh_root.get_node_or_null("BeamLight") as OmniLight3D
	if beam_light:
		beam_light.position = Vector3(0.0, 0.0, -_current_beam_length * 0.5)

	_beam_damage_timer += delta
	if _beam_damage_timer >= 0.25: #1.0 = 1 second
		_beam_damage_timer = 0.0
		if hit_player and _player:
			_player.take_damage(int(attack_damage * 0.75), _beam_aim_dir, 0.0, 0.0) #damage 
			if blood_particles:
				blood_particles.restart()

func _stop_sustained_beam() -> void:
	if not _is_beaming:
		return
	_is_beaming = false
	
	if beam_sfx and beam_sfx.playing:
		var sfx_tween := create_tween()
		sfx_tween.tween_property(beam_sfx, "volume_db", -80.0, 0.5)
		sfx_tween.tween_callback(beam_sfx.stop)
		
	if _beam_mesh_root:
		var tween := create_tween()
		for child in _beam_mesh_root.get_children():
			if child is MeshInstance3D:
				var mat: BaseMaterial3D = child.get_surface_override_material(0) as BaseMaterial3D
				if mat:
					tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.25)
		tween.tween_callback(_beam_mesh_root.queue_free)
		_beam_mesh_root = null

func take_hit(damage: int, knockback_dir: Vector3, knockback_force: float = 6.0) -> void:
	if chaos_state == ChaosState.DEAD:
		return
	hp -= damage
	if blood_particles:
		blood_particles.restart()
	print("[CHAOS] take_hit | damage: ", damage, " | hp now: ", hp, " | chaos_state: ", chaos_state)
	_update_phase()
	if hp <= 0:
		_die()
		return
	if damage >= 30:
		print("[CHAOS] heavy hit -> stagger")
		_knockback_vel = knockback_dir * (knockback_force * 0.25)
		_stagger_t = 0.2
		_is_doing_ability = false
		_stop_sustained_beam()
		_is_flying_smash = false
		chaos_state = ChaosState.STAGGERED
		state = State.STAGGERED
	if flesh_sfx:
		flesh_sfx.pitch_scale = randf_range(0.95, 1.05)
		flesh_sfx.play()

func _die() -> void:
	print("[CHAOS] _die called")
	
	if music_player.playing:
		var music_tween := create_tween()
		music_tween.tween_property(music_player, "volume_db", -80.0, 2.5)
		music_tween.tween_callback(music_player.stop)
	
	await get_tree().create_timer(3.1).timeout
	roar_sfx.pitch_scale = randf_range(0.75, 0.85)
	roar_sfx.play()

	_stop_sustained_beam()
	chaos_state = ChaosState.DEAD
	state = State.DEAD
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	set_physics_process(false)
	_is_doing_ability = false
	_is_flying_smash = false
	for minion in _spawned_minions:
		if is_instance_valid(minion):
			minion.queue_free()
	_spawned_minions.clear()

	if anim_controller:
		anim_controller.death()
	GameManager.add_souls(soul_drop)
	GameManager.add_shards(shard_drop)
	get_parent().emit_signal("boss_defeated")
	await get_tree().create_timer(7 - 3.1 + 10.0).timeout
	var ft := create_tween()
	_fade_out(self, 1.5, ft)
	await ft.finished
	queue_free()

func _fade_out(node: Node, duration: float, tween: Tween) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			for i in child.get_surface_override_material_count():
				var mat: BaseMaterial3D = child.get_active_material(i) as BaseMaterial3D
				if mat:
					var unique: BaseMaterial3D = mat.duplicate() as BaseMaterial3D
					unique.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					child.set_surface_override_material(i, unique)
					tween.parallel().tween_property(unique, "albedo_color:a", 0.0, duration)
		_fade_out(child, duration, tween)

func _find_anim_controller(node: Node) -> ChaosAnim:
	for child in node.get_children():
		if child is ChaosAnim:
			return child
		var found := _find_anim_controller(child)
		if found:
			return found
	return null

func _spawn_floor_crater(spawn_pos: Vector3, radius: float) -> void:
	var decal := Decal.new()
	
	var texture_path := "res://assets/textures/crater.png"
	if ResourceLoader.exists(texture_path):
		decal.texture_albedo = load(texture_path)
	else:
		push_warning("Crater texture missing at: " + texture_path)
		return
		
	get_parent().add_child(decal)
	decal.global_position = spawn_pos + Vector3(0.0, -0.05, 0.0)
	
	var diameter := radius * 2.0
	decal.size = Vector3(diameter, 2.0, diameter)
	decal.cull_mask = 1
	
	var decal_tween := create_tween()
	decal_tween.tween_interval(5.0)
	decal_tween.tween_property(decal, "modulate:a", 0.0, 2.0)
	decal_tween.tween_callback(decal.queue_free)

func play_intro_roar() -> void:
	if roar_sfx:
		roar_sfx.pitch_scale = randf_range(0.9, 1.1)
		roar_sfx.play()
	if anim_controller:
		anim_controller.roar(func(): pass)
