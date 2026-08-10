class_name Player
extends CharacterBody3D

@export var move_speed: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var roll_speed: float = 10.0
@export var roll_duration: float = 0.35
@export var roll_cooldown: float = 0.9
@export var gravity: float = 20.0
@export var max_hp: int = 100
@export var bob_frequency: float = 2.4
@export var bob_amplitude: float = 0.06
@export var sway_amount: float = 0.05
@export var max_sway: float = 0.15
@export var sway_smoothing: float = 8.0
@onready var camera_arm: Node3D = $CameraArm
@onready var weapon_mesh: Node3D = $CameraArm/Camera3D/HandPivot/SwayPivot
@onready var pulse_sfx: AudioStreamPlayer3D = $PulseSFX
var target_roll_tilt: float = 0.0
var target_roll_dip: float = 0.0
var _is_dead: bool = false
var mouse_input_x: float = 0.0
var mouse_input_y: float = 0.0
var bob_time: float = 0.0
var is_stunned: bool = false
var stun_timer: float = 0.0
var _shake_trauma: float = 0.0
var _shake_max_offset: float = 0.008
enum Equipment { SWORD, TORCH }
var current_equipment: Equipment = Equipment.SWORD
var _attack_buffer_timer: float = 0.0
var _roll_buffer_timer: float = 0.0
var buffer_window: float = 0.25
var _debug_stam_timer: float = 0.0
var _shake_intensity: float = 0.0
var _shake_decay: float = 5.0
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 20.0
@export var stamina_regen_delay: float = 5.0
@export var roll_stamina_cost: float = 15.0
@export var block_stamina_cost: float = 8.0
@export var attack_stamina_cost: float = 15.0
@onready var sword: Sword = $CameraArm/Camera3D/HandPivot/Sword
@onready var sword_mesh: Node3D = $CameraArm/Camera3D/HandPivot/SwayPivot/Sketchfab_Scene
@onready var walk_sfx: AudioStreamPlayer3D = $WalkSFX

var stamina: float = 100.0
var _stamina_regen_timer: float = 0.0
var _draining_stamina: bool = false

@onready var camera: Camera3D = $CameraArm/Camera3D
@onready var hand_pivot: Node3D = $CameraArm/Camera3D/HandPivot
@onready var sword_anim: AnimationPlayer = $CameraArm/Camera3D/HandPivot/AnimationPlayer
@onready var interaction: InteractionSystem = $InteractionSystem
@onready var slice_sfx: AudioStreamPlayer3D = $SliceSFX
@onready var impact_sfx: AudioStreamPlayer3D = $ImpactSFX
@onready var blood_particles: GPUParticles3D = $BloodParticles
@onready var torch: Node3D = $CameraArm/Camera3D/HandPivot/Torch

var hp: int = max_hp
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_direction: Vector3 = Vector3.ZERO
var roll_cooldown_timer: float = 0.0
var is_blocking: bool = false
var can_attack: bool = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	max_hp = GameManager.get_effective_max_hp()
	max_stamina = GameManager.get_effective_max_stamina()
	sword.visible = true
	if sword_mesh:
		sword_mesh.visible = true
	if torch:
		torch.visible = false
	move_speed = GameManager.get_move_speed()
	roll_cooldown = GameManager.get_roll_cooldown()
	stamina_regen_rate = GameManager.get_effective_stamina_regen()
	hp = GameManager.player_current_hp if GameManager.player_current_hp != -1 else max_hp
	stamina = GameManager.player_current_stamina if GameManager.player_current_stamina != -1.0 else max_stamina
func save_state() -> void:
	GameManager.save_player_state(hp, stamina)
func _unhandled_input(event: InputEvent) -> void:
	if _is_menu_open():
		return
	if event is InputEventMouseMotion:
		var current_sensitivity := mouse_sensitivity if not is_rolling else mouse_sensitivity * 0.5
		
		rotate_y(-event.relative.x * current_sensitivity)
		
		camera_arm.rotate_x(-event.relative.y * current_sensitivity)
		camera_arm.rotation.x = clamp(camera_arm.rotation.x, -1.3, 1.3)
		
		mouse_input_x = -event.relative.x * sway_amount
		mouse_input_y = -event.relative.y * sway_amount
func _make_noise(radius: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("hear_noise"):
			if global_position.distance_to(e.global_position) <= radius:
				e.hear_noise(global_position)
func _process(delta: float) -> void:
	if _shake_intensity > 0.0:
		_shake_intensity = move_toward(_shake_intensity, 0.0, _shake_decay * delta)
		
		var shake_offset_x := randf_range(-_shake_intensity, _shake_intensity)
		var shake_offset_y := randf_range(-_shake_intensity, _shake_intensity)
		var shake_offset_z := randf_range(-_shake_intensity, _shake_intensity)
		
		camera.h_offset = shake_offset_x
		camera.v_offset = shake_offset_y
	
	is_blocking = Input.is_action_pressed("block") and not is_rolling and stamina > 0.0

	if Input.is_action_just_pressed("swap_weapon") and not is_rolling and not _is_menu_open():
		_swap_equipment()
	if Input.is_action_just_pressed("use_item_1") and not _is_menu_open():
		_use_consumable("health_potion")
	if Input.is_action_just_pressed("use_item_2") and not _is_menu_open():
		_use_consumable("vigor_draught")
	if Input.is_action_just_pressed("attack"):
		_attack_buffer_timer = buffer_window
	if Input.is_action_just_pressed("roll"):
		_roll_buffer_timer = buffer_window

	if _attack_buffer_timer > 0.0:
		_attack_buffer_timer -= delta
		if can_attack and not is_rolling and not _is_menu_open() and current_equipment == Equipment.SWORD:
			_attack_buffer_timer = 0.0
			_swing()

	if _roll_buffer_timer > 0.0:
		_roll_buffer_timer -= delta
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if input_dir.length() > 0.1 and roll_cooldown_timer <= 0.0 and not is_rolling:
			var forward := -global_basis.z
			var right := global_basis.x
			var move_vec := (forward * -input_dir.y + right * input_dir.x).normalized()
			_roll_buffer_timer = 0.0
			_start_roll(move_vec)
	
	_tick_stamina(delta)
	_update_pulse_sfx()
	if not is_rolling:
		target_roll_tilt = 0.0
		target_roll_dip = 0.0
		
		if is_on_floor() and velocity.length() > 0.5:
			var old_bob := bob_time
			bob_time += delta * velocity.length()
			var bob_offset := sin(bob_time * bob_frequency) * bob_amplitude
			camera.position.y = move_toward(camera.position.y, bob_offset, delta * 5.0)
			
			if sin(old_bob * bob_frequency) > 0.0 and sin(bob_time * bob_frequency) <= 0.0:
				walk_sfx.pitch_scale = randf_range(0.85, 1.15)
				walk_sfx.play()
				_make_noise(6.0)
		else:
			camera.position.y = move_toward(camera.position.y, 0.0, delta * 5.0)

		mouse_input_x = clamp(mouse_input_x, -max_sway, max_sway)
		mouse_input_y = clamp(mouse_input_y, -max_sway, max_sway)
		var target_sway_rot := Vector3(mouse_input_y, mouse_input_x, 0.0)
		weapon_mesh.rotation = weapon_mesh.rotation.lerp(target_sway_rot, delta * sway_smoothing)

		mouse_input_x = lerp(mouse_input_x, 0.0, delta * 15.0)
		mouse_input_y = lerp(mouse_input_y, 0.0, delta * 15.0)
		
		camera.rotation.z = lerp(camera.rotation.z, 0.0, delta * 8.0)
		
	else:
		camera.rotation.z = lerp(camera.rotation.z, target_roll_tilt, delta * 12.0)
		
		camera.position.y = lerp(camera.position.y, target_roll_dip, delta * 15.0)
		
		if roll_timer < (roll_duration * 0.5):
			target_roll_dip = 0.0
func _tick_shake(delta: float) -> void:
	if _shake_trauma <= 0.0:
		return
	_shake_trauma = max(_shake_trauma - delta * 2.5, 0.0)
	var shake: float = _shake_trauma * _shake_trauma
	camera.h_offset = randf_range(-1.0, 1.0) * _shake_max_offset * shake
	camera.v_offset = randf_range(-1.0, 1.0) * _shake_max_offset * shake
	if _shake_trauma <= 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
func _swap_equipment() -> void:
	if current_equipment == Equipment.SWORD:
		current_equipment = Equipment.TORCH
		if sword_mesh:
			sword_mesh.visible = false
		if torch:
			torch.visible = true
	else:
		current_equipment = Equipment.SWORD
		if torch:
			torch.visible = false
		if sword_mesh:
			sword_mesh.visible = true
func add_shake(trauma: float) -> void:
	_shake_trauma = min(_shake_trauma + trauma, 1.0)
func _get_hud() -> HUD:
	return get_tree().get_first_node_in_group("hud") as HUD
func _is_menu_open() -> bool:
	for menu in get_tree().get_nodes_in_group("blocking_menu"):
		if menu.visible:
			return true
	return false
func _tick_stamina(delta: float) -> void:
	var draining := false

	if is_blocking:
		stamina -= block_stamina_cost * delta
		stamina = max(stamina, 0.0)
		draining = true

	if draining:
		_stamina_regen_timer = stamina_regen_delay
	else:
		if _stamina_regen_timer > 0.0:
			_stamina_regen_timer -= delta
		else:
			var effective_regen: float = stamina_regen_rate * lerp(1.0, 0.3, _critical_severity())
			stamina += effective_regen * delta
			stamina = min(stamina, max_stamina)

	_debug_stam_timer += delta
	if _debug_stam_timer >= 1.0:
		_debug_stam_timer = 0.0

	var h := _get_hud()
	if h:
		h.update_stamina(stamina, max_stamina)
func _physics_process(delta: float) -> void:
	if _is_menu_open():
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y = 0.0
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	if is_stunned:
		stun_timer -= delta
		if not is_on_floor():
			velocity.y -= gravity * delta * 2.5
		velocity.x = lerp(velocity.x, 0.0, delta * 8.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 8.0)
		if stun_timer <= 0.0:
			is_stunned = false

	elif is_rolling:
		roll_timer -= delta
		velocity = roll_direction * roll_speed
		velocity.y -= gravity * delta
		if roll_timer <= 0.0:
			is_rolling = false
	else:
		_handle_move(delta)

	if roll_cooldown_timer > 0.0:
		roll_cooldown_timer -= delta

	move_and_slide()
func _handle_move(delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var forward := -global_basis.z
	var right := global_basis.x
	var move_vec := (forward * -input_dir.y + right * input_dir.x).normalized()

	var severity := _critical_severity()
	var effective_speed: float = move_speed * lerp(1.0, 0.55, severity)

	velocity.x = move_vec.x * effective_speed
	velocity.z = move_vec.z * effective_speed
func _update_pulse_sfx() -> void:
	if hp <= 0:
		pulse_sfx.stop()
		return
	var is_critical := _critical_severity() > 0.0
	
	if is_critical and not pulse_sfx.playing:
		pulse_sfx.play()
	elif not is_critical and pulse_sfx.playing:
		pulse_sfx.stop()
func _start_roll(direction: Vector3) -> void:
	if stamina < roll_stamina_cost:
		return
	_make_noise(12.0)
	stamina -= roll_stamina_cost
	stamina = max(stamina, 0.0)
	_stamina_regen_timer = stamina_regen_delay
	
	
	is_rolling = true
	roll_timer = roll_duration
	roll_cooldown_timer = roll_cooldown
	roll_direction = direction
	_tween_camera_roll(direction)
func _tween_camera_roll(direction: Vector3) -> void:
	var is_rolling_right = direction.dot(global_basis.x) > 0.1
	var is_rolling_left = direction.dot(global_basis.x) < -0.1
	
	if is_rolling_right:
		target_roll_tilt = -0.15
	elif is_rolling_left:
		target_roll_tilt = 0.15
	else:
		target_roll_tilt = 0.05
		
	target_roll_dip = -0.4
func _swing() -> void:
	if stamina < attack_stamina_cost:
		return
		
	stamina -= attack_stamina_cost
	stamina = max(stamina, 0.0)
	_stamina_regen_timer = stamina_regen_delay
	
	can_attack = false
	sword_anim.play("swing")
	slice_sfx.pitch_scale = randf_range(0.8, 1)
	slice_sfx.play()
	_make_noise(12.0)
	var base_fov := camera.fov
	var fov_tween = create_tween()
	fov_tween.tween_property(camera, "fov", base_fov - 6.0, 0.05).set_trans(Tween.TRANS_SINE)
	fov_tween.tween_property(camera, "fov", base_fov, 0.25).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(0.1).timeout
	
	if can_attack:
		return
		
	sword.enable_hitbox()
	
	await get_tree().create_timer(0.15).timeout
	
	if can_attack:
		return
		
	sword.disable_hitbox()
	
	if sword_anim.is_playing() and sword_anim.current_animation == "swing":
		await sword_anim.animation_finished
		
	sword_anim.play("RESET")
	can_attack = true
func take_damage(amount: int, attack_direction: Vector3 = Vector3.ZERO, knockback_force: float = 7.0, stun_duration: float = 0.25) -> void:
	if is_rolling:
		return
	
	if is_blocking and _is_in_front(attack_direction):
		# TODO: Play a shield block spark / chime effect here!
		return
		
	hp -= amount
	hp = max(hp, 0)
	var h := _get_hud()
	if h:
		h.take_damage_flash(hp, max_hp)
	impact_sfx.pitch_scale = randf_range(0.9, 1)
	impact_sfx.play()
	if blood_particles:
		blood_particles.restart()
	var flash_tween = create_tween()
	$CanvasLayer/DamageFlash.color.a = 0.4
	flash_tween.tween_property($CanvasLayer/DamageFlash, "color:a", 0.0, 0.3)
	if hp > 0 and attack_direction != Vector3.ZERO:
		is_stunned = true
		is_rolling = false
		stun_timer = stun_duration
		
		can_attack = true
		sword.disable_hitbox()
		sword_anim.play("RESET")
		
		var launch_dir = attack_direction.normalized()
		velocity.x = launch_dir.x * knockback_force
		velocity.z = launch_dir.z * knockback_force
		_tween_camera_hit(launch_dir)
		
	if hp <= 0:
		_die()
func heal(amount: int) -> void:
	hp = min(hp + amount,max_hp)
	var h := _get_hud()
	if h:
		h.heal(hp,max_hp)
func restore_stamina(amount: float) -> void:
	stamina = min(stamina + amount,max_stamina)
func _use_consumable(id: String) -> void:
	if not GameManager.use_consumable(id):
		return
	match id:
		"health_potion":
			heal(40)
		"vigor_draught":
			restore_stamina(40)
func _tween_camera_hit(launch_dir: Vector3) -> void:
	var hit_side = launch_dir.dot(global_basis.x)
	var tilt = 0.08 if hit_side > 0 else -0.08
	
	var tween = create_tween()
	tween.tween_property(camera, "rotation:z", tilt, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "rotation:z", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC)
func _is_in_front(dir: Vector3) -> bool:
	return dir.dot(-global_basis.z) > 0.4
func _critical_threshold() -> float:
	return clamp(35.0 / float(max_hp), 0.05, 0.25)

func _critical_severity() -> float:
	var threshold := _critical_threshold()
	var pct := float(hp) / float(max_hp)
	if pct >= threshold:
		return 0.0
	return 1.0 - (pct / threshold)
func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	
	is_rolling = false
	is_blocking = false
	can_attack = false
	velocity = Vector3.ZERO
	
	pulse_sfx.stop()
	GameManager.save()
	set_physics_process(false)
	set_process_unhandled_input(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_play_death_collapse()
func apply_shake(amount: float, decay_rate: float = 5.0) -> void:
	_shake_intensity = amount
	_shake_decay = decay_rate
func _play_death_collapse() -> void:
	var tween := create_tween()
	tween.set_parallel(false)

	tween.tween_property(camera, "rotation:z", deg_to_rad(25.0), 0.3)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_CUBIC)

	tween.tween_property($CameraArm, "position:y", 0.2, 1.1)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_CUBIC)

	tween.parallel().tween_property(camera, "rotation:x", deg_to_rad(-15.0), 0.8)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_CUBIC)

	tween.tween_property(camera, "rotation:z", deg_to_rad(85.0), 0.4)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)

	tween.tween_interval(0.8)

	tween.tween_callback(_fade_to_base)
	
func _fade_to_base() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.modulate.a = 0.0
	get_viewport().add_child(overlay)

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 1.2)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		overlay.queue_free()
		GameManager.fade_in_on_load = true
		GameManager.on_player_died()
	)
