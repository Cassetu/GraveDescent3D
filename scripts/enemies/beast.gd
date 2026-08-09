class_name Beast
extends Enemy

var anim_controller: BeastAnim = null
var _attack_index: int = 0
var walk_sfx_timer: float = 0.0
const WALK_SFX_INTERVAL: float = 0.435

@export var soul_drop: int = 2
@export var shard_drop: int = 15

@onready var flesh_sfx: AudioStreamPlayer3D = $FleshSFX
@onready var roar_sfx: AudioStreamPlayer3D = $RoarSFX
@onready var claw_sfx: AudioStreamPlayer3D = $ClawSFX
@onready var walk_sfx: AudioStreamPlayer3D = $WalkSFX

@onready var blood_particles: GPUParticles3D = $BloodParticles

const DEATH_START := 4.9
const DEATH_END := 5.9833

var _last_state: State = State.IDLE

func _ready() -> void:
	max_hp = 120
	move_speed = 5 #3.7
	attack_damage = 12
	attack_range = 3
	attack_cooldown = 0.65
	super._ready()
	await get_tree().process_frame
	anim_controller = _find_anim_controller(self)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if velocity.length() > 0.1 and state != State.DEAD and state != State.STAGGERED and state != State.ATTACK:
		walk_sfx_timer -= delta
		if walk_sfx_timer <= 0.0:
			walk_sfx.pitch_scale = randf_range(0.9, 1.1)
			walk_sfx.play()
			walk_sfx_timer = WALK_SFX_INTERVAL

	if anim_controller and state != State.ATTACK and state != State.STAGGERED and state != State.DEAD:
		if state == State.IDLE:
			if velocity.length() > 0.1:
				if anim_controller._current != "walk":
					anim_controller.walk()
			else:
				if anim_controller._current != "idle":
					anim_controller.idle()
		elif state == State.CHASE:
			if anim_controller._current != "walk":
				anim_controller.walk()
				
	_last_state = state

func _do_attack() -> void:
	_last_state = State.ATTACK
	
	if anim_controller:
		if _attack_index % 2 == 0:
			anim_controller.attack(func(): _on_attack_complete())
			claw_sfx.pitch_scale = randf_range(0.9, 1.1)
			claw_sfx.play()
		else:
			anim_controller.ram(func(): _on_attack_complete())
	_attack_index += 1
	if _player:
		var dir: Vector3 = (_player.global_position - global_position).normalized()
		_player.take_damage(attack_damage, dir)

func _on_attack_complete() -> void:
	if state == State.CHASE:
		anim_controller.walk()
	elif state == State.IDLE:
		anim_controller.idle()

func take_hit(damage: int, knockback_dir: Vector3, knockback_force: float = 6.0) -> void:
	var previous_state = state
	super.take_hit(damage, knockback_dir, knockback_force)
	if blood_particles:
		blood_particles.restart()
	flesh_sfx.pitch_scale = randf_range(0.95, 1.05)
	flesh_sfx.play()
	roar_sfx.pitch_scale = randf_range(0.9, 1.1)
	roar_sfx.play()
	walk_sfx.pitch_scale = 0.8
	walk_sfx.play()
	if state == State.STAGGERED and previous_state != State.STAGGERED:
		_last_state = State.STAGGERED
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

	var anim_duration := DEATH_END - DEATH_START
	await get_tree().create_timer(anim_duration + 10.0).timeout

	var fade_tween := create_tween()
	_fade_out(self, 1.5, fade_tween)
	await fade_tween.finished
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

func _find_anim_controller(node: Node) -> BeastAnim:
	for child in node.get_children():
		if child is BeastAnim:
			return child
		var found := _find_anim_controller(child)
		if found:
			return found
	return null
