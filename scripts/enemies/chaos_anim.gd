class_name ChaosAnim
extends Node3D

var anim_player: AnimationPlayer = null

var _current: String = ""
var _loop: bool = false
var _stop_at: float = -1.0
var _hold_last_frame: bool = false
var _finished_callback: Callable

func _ready() -> void:
	anim_player = _find_anim_player(get_parent())
	if not anim_player:
		push_error("ChaosAnim: no AnimationPlayer found")
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
		return
	if _stop_at >= 0.0 and anim_player.current_animation_position >= _stop_at - 0.05:
		if _hold_last_frame:
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
	if _current == anim_name and loop and anim_player.is_playing():
		return
	_current = anim_name
	_loop = loop
	_stop_at = stop_at
	_hold_last_frame = false
	_finished_callback = on_finish
	anim_player.play(anim_name)
	if loop:
		anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR

func idle() -> void:
	_play("cbbm_id0", true)

func walk() -> void:
	_play("cbbm_02f_lp0", true)

func punch_close(on_finish: Callable = Callable()) -> void:
	_play("cbbm_atk1", false, -1.0, on_finish)

func punch_out(on_finish: Callable = Callable()) -> void:
	_play("cbbm_sp01", false, -1.0, on_finish)

func roar(on_finish: Callable = Callable()) -> void:
	_play("cbbm_sp02", false, -1.0, on_finish)

func grab(on_finish: Callable = Callable()) -> void:
	_play("cbbm_sp03", false, -1.0, on_finish)

func flying_smash(on_finish: Callable = Callable()) -> void:
	_play("cbbm_sp04", false, -1.0, on_finish)

func summon(on_finish: Callable = Callable()) -> void:
	_play("cbbm_sp09", false, -1.0, on_finish)

func fly_summon_beam(on_finish: Callable = Callable()) -> void:
	_play("cbbm_sp10", false, -1.0, on_finish)

func strafe_left() -> void:
	_play("cbbm_trn_l_lp", true)

func strafe_right() -> void:
	_play("cbbm_trn_r_lp", true)

func death() -> void:
	_current = "death"
	_play("cbbm_hide_sp01", false, -1.0)

func stop() -> void:
	if anim_player:
		anim_player.stop()
	_stop_at = -1.0
	_loop = false

func _on_anim_finished(_anim_name: String) -> void:
	if _current == "walk" or _current == "idle" or _current == "strafe_left" or _current == "strafe_right":
		return
	_stop_at = -1.0
	var cb := _finished_callback
	_finished_callback = Callable()
	if cb.is_valid():
		cb.call()
