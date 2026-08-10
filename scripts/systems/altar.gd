extends Node3D

func _ready() -> void:
	var anim_player := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if not anim_player:
		return
	var clip := anim_player.get_animation("Clip")
	if clip:
		clip.loop_mode = Animation.LOOP_LINEAR
	anim_player.play("Clip")
