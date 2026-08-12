class_name ScourgerAnim
extends Node3D

var anim_player: AnimationPlayer = null

var _current: String = ""
var _stop_at: float = -1.0
var _hold_last_frame: bool = false
var _finished_callback: Callable

func _ready() -> void:
	anim_player = _find_anim_player(self)
	if not anim_player:
		push_error("ScourgerAnim: no AnimationPlayer found")
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
		if _current == "walk" or _current == "idle" or _current == "walk_backward":
			anim_player.play(anim_player.current_animation)
		return
	if _stop_at >= 0.0 and anim_player.current_animation_position >= _stop_at - 0.05:
		if _current == "walk" or _current == "idle" or _current == "walk_backward":
			return
		elif _hold_last_frame:
			anim_player.pause()
			_stop_at = -1.0
		else:
			anim_player.stop()
			_stop_at = -1.0
			var cb := _finished_callback
			_finished_callback = Callable()
			if cb.is_valid():
				cb.call()

func idle() -> void:
	if _current == "idle" and anim_player.is_playing():
		return
	_current = "idle"
	_stop_at = -1.0
	_hold_last_frame = false
	_finished_callback = Callable()
	anim_player.play("Idle")
	anim_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR

func walk() -> void:
	if _current == "walk" and anim_player.is_playing():
		return
	_current = "walk"
	_stop_at = -1.0
	_hold_last_frame = false
	_finished_callback = Callable()
	anim_player.play("Walk")
	anim_player.get_animation("Walk").loop_mode = Animation.LOOP_LINEAR

func walk_backward() -> void:
	if _current == "walk_backward" and anim_player.is_playing():
		return
	_current = "walk_backward"
	_stop_at = -1.0
	_hold_last_frame = false
	_finished_callback = Callable()
	anim_player.get_animation("Walk").loop_mode = Animation.LOOP_LINEAR
	anim_player.play("Walk", -1, -1.0, true)

func plunge_attack(on_finish: Callable = Callable()) -> void:
	_current = "plunge_attack"
	_stop_at = -1.0
	_hold_last_frame = false
	_finished_callback = on_finish
	anim_player.play("Plunge Attack")

func rear_attack(on_finish: Callable = Callable()) -> void:
	_current = "rear_attack"
	_stop_at = -1.0
	_hold_last_frame = false
	_finished_callback = on_finish
	anim_player.play("Rear Attack")

func stagger() -> void:
	_current = "stagger"
	_hold_last_frame = true
	_stop_at = anim_player.current_animation_position
	_finished_callback = Callable()
	anim_player.pause()

func death() -> void:
	_current = "death"
	_hold_last_frame = true
	_stop_at = anim_player.current_animation_position
	_finished_callback = Callable()
	anim_player.pause()

func stop() -> void:
	if anim_player:
		anim_player.stop()
	_stop_at = -1.0

func _on_anim_finished(_anim_name: String) -> void:
	if _current == "walk" or _current == "idle" or _current == "walk_backward":
		return
	_stop_at = -1.0
