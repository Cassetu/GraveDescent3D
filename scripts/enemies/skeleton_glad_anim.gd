class_name SkeletonGladAnim
extends Node3D

var anim_player: AnimationPlayer = null

var _current: String = ""
var _stop_at: float = -1.0
var _loop: bool = false
var _hold_last_frame: bool = false
var _finished_callback: Callable

func _ready() -> void:
	anim_player = _find_anim_player(get_parent())
	if not anim_player:
		push_error("SkeletonGladAnim: no AnimationPlayer found")
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
	if not anim_player or not anim_player.is_playing():
		if _current == "walk" or _current == "idle":
			anim_player.play(anim_player.current_animation)
		return
	if _stop_at >= 0.0 and anim_player.current_animation_position >= _stop_at - 0.05:
		if _current == "walk" or _current == "idle":
			return
		elif _hold_last_frame:
			anim_player.seek(_stop_at, true)
			anim_player.pause()
			_stop_at = -1.0
		else:
			anim_player.stop()
			_stop_at = -1.0
			var cb := _finished_callback
			_finished_callback = Callable()
			if cb.is_valid():
				cb.call()

func _play(anim_name: String, loop: bool = false, stop_at: float = -1.0, on_finish: Callable = Callable()) -> void:
	_current = anim_name
	_loop = loop
	_stop_at = stop_at
	_hold_last_frame = false
	_finished_callback = on_finish
	anim_player.play(anim_name)

func idle() -> void:
	if _current == "idle" and anim_player.is_playing():
		return
	_current = "idle"
	_stop_at = -1.0
	_hold_last_frame = false
	_finished_callback = Callable()
	anim_player.play("Lesha_idle")
	anim_player.get_animation("Lesha_idle").loop_mode = Animation.LOOP_LINEAR

func walk() -> void:
	if _current == "walk" and anim_player.is_playing():
		return
	_current = "walk"
	_loop = false
	_stop_at = -1.0
	_hold_last_frame = false
	_finished_callback = Callable()
	anim_player.play("Lesha_walk")
	anim_player.get_animation("Lesha_walk").loop_mode = Animation.LOOP_LINEAR

func attack(on_finish: Callable = Callable()) -> void:
	_current = "attack"
	_play("Lesha_attack_1", false, -1.0, on_finish)

func stagger() -> void:
	_play("Lesha_hitted_1", false)

func death() -> void:
	_current = "death"
	_loop = false
	_stop_at = 0.36
	_hold_last_frame = true
	_finished_callback = Callable()
	anim_player.play("Lesha_hitted_2")

func stop() -> void:
	if anim_player:
		anim_player.stop()
	_stop_at = -1.0
	_loop = false

func _on_anim_finished(anim_name: String) -> void:
	if _current == "walk" or _current == "idle":
		return
	_stop_at = -1.0
