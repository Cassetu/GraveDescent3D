class_name BossRoom
extends DungeonRoom

signal boss_defeated

@onready var exit_gate: Node3D = $ExitGate
@onready var cutscene_player: AnimationPlayer = $CutscenePlayer
@onready var cutscene_camera: Camera3D = $CutsceneCamera

var _player: Player = null
var _boss: Chaos = null

func _ready() -> void:
	super._ready()
	
	for exit in find_children("*", "Area3D"):
		if exit.is_in_group("room_exit"):
			exit.monitoring = false
			
	boss_defeated.connect(_on_boss_defeated)
	
	_setup_and_play_intro()

func _setup_and_play_intro() -> void:
	await get_tree().process_frame
	
	_player = get_tree().get_first_node_in_group("player") as Player
	_boss = get_tree().get_first_node_in_group("enemy") as Chaos
	
	if not _player or not _boss or not cutscene_player or not cutscene_camera:
		push_warning("[BOSS ROOM] Cutscene nodes or characters missing!")
		return

	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	
	_boss.is_in_cutscene = true
	_boss.chaos_state = _boss.ChaosState.IDLE
	
	cutscene_camera.make_current()
	
	cutscene_player.play("intro")
	await cutscene_player.animation_finished
	
	var blend_tween := create_tween()
	blend_tween.set_parallel(true)
	blend_tween.set_ease(Tween.EASE_IN_OUT)
	blend_tween.set_trans(Tween.TRANS_CUBIC)
	
	blend_tween.tween_property(cutscene_camera, "global_position", _player.camera.global_position, 0.8)
	blend_tween.tween_property(cutscene_camera, "global_transform:basis", _player.camera.global_transform.basis, 0.8)
	await blend_tween.finished
	
	_player.camera.make_current()
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)
	
	_boss.is_in_cutscene = false
	_boss._enter_walking()

func _on_boss_defeated() -> void:
	var tween := create_tween()
	tween.tween_property(exit_gate, "position:y", exit_gate.position.y + 4.0, 1.2)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1.5).timeout
	for exit in find_children("*", "Area3D"):
		if exit.is_in_group("room_exit"):
			exit.monitoring = true
