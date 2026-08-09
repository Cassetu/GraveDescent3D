class_name BeastAnim
extends Node3D

var anim_player: AnimationPlayer = null
var _hold_last_frame: bool = false

const ATTACK_START := 0.0
const ATTACK_END := 0.65
const RAM_START := 0.65
const RAM_END := 1.33
const DAMAGE_START := 1.33
const DAMAGE_END := 1.75
const IDLE_START := 2.45
const IDLE_END := 3.31
const WALK_START := 3.33
const WALK_END := 4.9
const DEATH_START := 4.9
const DEATH_END := 5.9833

var _current: String = ""
var _start_at: float = 0.0
var _stop_at: float = 0.0
var _loop: bool = false
var _finished_callback: Callable

func _ready() -> void:
	anim_player = _find_anim_player(get_parent())
	if not anim_player:
		push_error("BeastAnim: no AnimationPlayer found in tree")
		return
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
	if _stop_at > 0.0 and anim_player.is_playing():
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

func _play(start: float, stop: float, loop: bool = false, speed: float = 1.0, on_finish: Callable = Callable()) -> void:
	_hold_last_frame = false
	_start_at = start
	_stop_at = stop
	_loop = loop
	_finished_callback = on_finish
	anim_player.play("Motion", -1, speed)
	anim_player.seek(start, true)

func attack(on_finish: Callable = Callable()) -> void:
	_current = "attack"
	_play(ATTACK_START, ATTACK_END, false, 1.0, on_finish)

func ram(on_finish: Callable = Callable()) -> void:
	_current = "ram"
	_play(RAM_START, RAM_END, false, 1.0, on_finish)

func idle() -> void:
	_current = "idle"
	_play(IDLE_START, IDLE_END, true, 1.0)

func walk() -> void:
	_current = "walk"
	_play(WALK_START, WALK_END, true, 1.0)

func stagger() -> void:
	_current = "stagger"
	_play(DAMAGE_START, DAMAGE_END, false, 1.0)

func death() -> void:
	_current = "death"
	_loop = false
	_hold_last_frame = true
	_play(DEATH_START, DEATH_END, false)

func stop() -> void:
	anim_player.stop()
	_stop_at = 0.0
	_loop = false

func _on_anim_finished(_anim_name: String) -> void:
	_stop_at = 0.0
