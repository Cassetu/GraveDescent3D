class_name Scourger
extends Enemy

enum EngagePhase { APPROACH, RETREAT }

var anim_controller: ScourgerAnim = null
var _phase: EngagePhase = EngagePhase.APPROACH
var _retreat_timer: float = 0.0
var _is_leaping: bool = false

@export var soul_drop: int = 3
@export var shard_drop: int = 20

@export var leap_trigger_range: float = 2.2
@export var retreat_distance: float = 4.0
@export var max_retreat_time: float = 1.6
@export var max_leap_distance: float = 5.0
@export var leap_impulse: float = 6.5
@export var plunge_damage_mult: float = 1.4
@export var rear_damage_mult: float = 1.0
@export var rear_ambush_dot: float = -0.3

const PLUNGE_LAUNCH_AT := 0.76
const PLUNGE_HIT_AT := 2.11
const REAR_HIT_AT := 1.17

@onready var flesh_sfx: AudioStreamPlayer3D = $FleshSFX
@onready var blood_particles: GPUParticles3D = $BloodParticles

func _ready() -> void:
	max_hp = 90
	move_speed = 4.5
	attack_damage = 14
	attack_range = leap_trigger_range
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

	if not is_on_floor() or _is_leaping:
		velocity.y -= gravity * delta

	match state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if _player and global_position.distance_to(_player.global_position) < sight_range:
				state = State.CHASE
				_phase = EngagePhase.APPROACH
			_handle_locomotion_animations()

		State.CHASE:
			_tick_engage(delta)

		State.ATTACK:
			if not _is_leaping:
				velocity.x = move_toward(velocity.x, 0.0, delta * 10.0)
				velocity.z = move_toward(velocity.z, 0.0, delta * 10.0)

		State.STAGGERED:
			velocity.x = move_toward(velocity.x, 0.0, delta * 10.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 10.0)

	move_and_slide()

func _tick_engage(delta: float) -> void:
	if not _player:
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var to_player_dir := to_player.normalized() if dist > 0.01 else Vector3.ZERO

	var forward := -global_basis.z
	forward.y = 0.0
	var dot_to_player := forward.normalized().dot(to_player_dir)

	if dot_to_player < rear_ambush_dot and dist <= attack_range * 1.6:
		_start_rear_attack()
		return

	if dist > 0.1:
		var target_angle := atan2(-to_player.x, -to_player.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 4.0)

	match _phase:
		EngagePhase.APPROACH:
			if dist <= leap_trigger_range:
				_phase = EngagePhase.RETREAT
				_retreat_timer = 0.0
			else:
				velocity.x = to_player_dir.x * move_speed
				velocity.z = to_player_dir.z * move_speed
			_handle_locomotion_animations()

		EngagePhase.RETREAT:
			_retreat_timer += delta
			var away_dir := -to_player_dir
			velocity.x = away_dir.x * move_speed * 0.8
			velocity.z = away_dir.z * move_speed * 0.8
			if anim_controller and anim_controller._current != "walk_backward":
				anim_controller.walk_backward()

			if dist >= retreat_distance or _retreat_timer >= max_retreat_time:
				_start_plunge()

func _handle_locomotion_animations() -> void:
	if not anim_controller:
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.1:
		if anim_controller._current != "walk":
			anim_controller.walk()
	else:
		if anim_controller._current != "idle":
			anim_controller.idle()

func _process_hit_timings(delta: float) -> void:
	if state != State.ATTACK or not anim_controller:
		return
	if not anim_controller.anim_player or not anim_controller.anim_player.is_playing():
		return
	var pos := anim_controller.anim_player.current_animation_position

	if anim_controller._current == "plunge_attack":
		if abs(pos - PLUNGE_LAUNCH_AT) < delta:
			_launch_plunge()
		if abs(pos - PLUNGE_HIT_AT) < delta:
			_is_leaping = false
			_perform_hit_check(plunge_damage_mult)

	elif anim_controller._current == "rear_attack":
		if abs(pos - REAR_HIT_AT) < delta:
			_perform_hit_check(rear_damage_mult)

func _start_plunge() -> void:
	state = State.ATTACK
	velocity.x = 0.0
	velocity.z = 0.0
	if anim_controller:
		anim_controller.plunge_attack(func(): _on_attack_complete())

func _start_rear_attack() -> void:
	state = State.ATTACK
	velocity.x = 0.0
	velocity.z = 0.0
	if anim_controller:
		anim_controller.rear_attack(func(): _on_attack_complete())

func _launch_plunge() -> void:
	if not _player:
		return
	_is_leaping = true
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var airborne_duration := PLUNGE_HIT_AT - PLUNGE_LAUNCH_AT
	var leap_dist: float = clamp(to_player.length(), 0.0, max_leap_distance)
	var leap_dir := to_player.normalized() if to_player.length() > 0.01 else -global_basis.z
	velocity.x = leap_dir.x * (leap_dist / airborne_duration)
	velocity.z = leap_dir.z * (leap_dist / airborne_duration)
	velocity.y = leap_impulse

func _perform_hit_check(dmg_mult: float) -> void:
	if not _player:
		return
	var to_p := _player.global_position - global_position
	if to_p.length() <= attack_range * 1.6:
		if _player.has_method("take_damage"):
			_player.take_damage(int(attack_damage * dmg_mult), to_p.normalized())

func _on_attack_complete() -> void:
	_is_leaping = false
	_phase = EngagePhase.APPROACH
	state = State.CHASE

func take_hit(amount: int, knockback_dir: Vector3 = Vector3.ZERO, knockback_force: float = 6.0) -> void:
	if state == State.DEAD:
		return
	var previous_state := state
	super.take_hit(amount, knockback_dir, knockback_force)
	if blood_particles:
		blood_particles.restart()
	if flesh_sfx:
		flesh_sfx.pitch_scale = randf_range(0.95, 1.05)
		flesh_sfx.play()
	if state == State.STAGGERED and previous_state != State.STAGGERED:
		_is_leaping = false
		if anim_controller:
			anim_controller.stagger()

func _die() -> void:
	state = State.DEAD
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	set_physics_process(false)

	if anim_controller:
		anim_controller.death()

	GameManager.add_souls(soul_drop)
	GameManager.add_shards(shard_drop)

	var fade_tween := create_tween()
	fade_tween.tween_interval(1.5)
	fade_tween.tween_callback(func():
		var t := create_tween()
		_fade_out(self, 1.5, t)
		t.finished.connect(queue_free))

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

func _find_anim_controller(node: Node) -> ScourgerAnim:
	for child in node.get_children():
		if child is ScourgerAnim:
			return child
		var found := _find_anim_controller(child)
		if found:
			return found
	return null
