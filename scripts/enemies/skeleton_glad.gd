class_name SkeletonGlad
extends Enemy

@export var soul_drop: int = 2
@export var shard_drop: int = 10
@export var drops_loot: bool = true
@onready var bone_sfx: AudioStreamPlayer3D = $BoneSFX
@onready var sword_sfx: AudioStreamPlayer3D = $SwordSFX

var anim_controller: SkeletonGladAnim = null
var _last_state: State = State.IDLE

const DEATH_HOLD_TIME := 3.0

func _ready() -> void:
	max_hp = 60
	move_speed = 0.8
	attack_damage = 14
	attack_range = 4
	attack_cooldown = 1.4167
	turn_speed = 4.0
	super._ready()
	await get_tree().process_frame
	anim_controller = _find_anim_controller(self)
	if anim_controller:
		anim_controller.idle()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
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

func _check_attack_hit(attack_origin: Vector3, attack_forward: Vector3) -> void:
	await get_tree().create_timer(0.5).timeout
	
	if state != State.ATTACK or not _player:
		return

	var to_player: Vector3 = (_player.global_position - global_position)
	to_player.y = 0.0

	var dist: float = to_player.length()
	var dot: float = 0.0
	
	if dist > 0.0:
		dot = attack_forward.dot(to_player.normalized())

	if dist <= attack_range and dot >= 0.7:
		var space_state := get_world_3d().direct_space_state
		var start_pos := global_position + Vector3(0.0, 1.0, 0.0)
		var end_pos := _player.global_position + Vector3(0.0, 1.0, 0.0)
		
		var query := PhysicsRayQueryParameters3D.create(start_pos, end_pos)
		query.exclude = [get_rid()]
		query.collision_mask = 1
		
		var result := space_state.intersect_ray(query)
		if result and not (result.collider is Player):
			return
			
		var dir: Vector3 = (_player.global_position - global_position).normalized()
		_player.take_damage(attack_damage, dir)
	else:
		if sword_sfx:
			sword_sfx.pitch_scale = randf_range(0.85, 1.15)
			sword_sfx.play()

func _do_attack() -> void:
	_last_state = State.ATTACK
	if anim_controller:
		anim_controller.attack(func(): _on_attack_complete())
	var forward: Vector3 = -global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	_check_attack_hit(global_position, forward)
func _on_attack_complete() -> void:
	if state == State.CHASE:
		anim_controller.walk()
	elif state == State.IDLE or state == State.ATTACK:
		anim_controller.idle()
func take_hit(damage: int, knockback_dir: Vector3, knockback_force: float = 6.0) -> void:
	var prev := state
	super.take_hit(damage, knockback_dir, knockback_force)
	bone_sfx.pitch_scale = randf_range(0.9, 1.1)
	bone_sfx.play()
	if state == State.STAGGERED and prev != State.STAGGERED:
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
	if drops_loot:
		GameManager.add_souls(soul_drop)
		GameManager.add_shards(shard_drop)
		
	await get_tree().create_timer(DEATH_HOLD_TIME + 10.0).timeout
	
	if not is_inside_tree():
		return
		
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
func _find_anim_controller(node: Node) -> SkeletonGladAnim:
	for child in node.get_children():
		if child is SkeletonGladAnim:
			return child
		var found := _find_anim_controller(child)
		if found:
			return found
	return null
