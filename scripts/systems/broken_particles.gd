extends Node3D

@onready var explosion_particles: GPUParticles3D = $ExplosionParticles
@onready var smash_sfx: AudioStreamPlayer3D = $SmashSFX

func _ready() -> void:
	if smash_sfx and smash_sfx.stream:
		smash_sfx.pitch_scale = randf_range(0.85, 1.15)
		smash_sfx.play()
		
	if explosion_particles:
		explosion_particles.emitting = true
		
	await get_tree().create_timer(1.5).timeout
	queue_free()
