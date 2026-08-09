class_name MonstrocityAnim
extends Node3D

var anim_player: AnimationPlayer = null
var _hold_last_frame: bool = false

var _current: String = ""
var _start_at: float = 0.0
var _stop_at: float = 0.0
var _loop: bool = false
var _finished_callback: Callable

func _ready() -> void:
	anim_player = _find_anim_player(get_parent())
	if anim_player:
		anim_player.animation_finished.connect(_on_anim_finished)

func _find_anim_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child
		var found := _find_anim_player(child)
		if found:
			return found
	return null

func _process(_delta: float) -> void:
	if _stop_at > 0.0 and anim_player and anim_player.is_playing():
		if anim_player.current_animation_position >= _stop_at:
			if _loop:
				anim_player.seek(_start_at, true)
			elif _hold_last_frame:
				anim_player.seek(_stop_at, true)
				anim_player.pause()
				_stop_at = 0.0
			else:
				anim_player.stop()
				_stop_at = 0.0
				var cb = _finished_callback
				_finished_callback = Callable()
				if cb.is_valid():
					cb.call()

func _play(anim_name: String, start: float, stop: float, loop: bool = false, speed: float = 1.0, on_finish: Callable = Callable()) -> void:
	_hold_last_frame = false
	_start_at = start
	_stop_at = stop
	_loop = loop
	_finished_callback = on_finish
	_current = anim_name
	anim_player.play(anim_name, -1, speed)
	anim_player.seek(start, true)

func idle() -> void:
	_play("idle_battle_1", 0.0, 1.46, true)

func walk() -> void:
	_play("walk_normal_1", 3.9, 5.56, true)

func run() -> void:
	_play("run_battle_1", 41.6, 42.8, true)

func claw(on_finish: Callable = Callable()) -> void:
	_play("att_battle_1_01", 5.58, 8.6333, false, 1.0, on_finish)

func claw_2(on_finish: Callable = Callable()) -> void:
	_play("att_battle_6_01", 28.1, 29.6, false, 1.0, on_finish)

func death() -> void:
	_hold_last_frame = true
	_play("dead_1", 34.1, 37.06, false)

func _on_anim_finished(_anim_name: String) -> void:
	_stop_at = 0.0
