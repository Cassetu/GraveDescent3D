extends Node3D

@onready var chunk_particles: GPUParticles3D = $ChunkParticles
@onready var splinter_particles: GPUParticles3D = $SplinterParticles
@onready var smash_sfx: AudioStreamPlayer3D = $SmashSFX

func _ready() -> void:
	if smash_sfx and smash_sfx.stream:
		smash_sfx.pitch_scale = randf_range(0.85, 1.15)
		smash_sfx.play()

	if chunk_particles:
		chunk_particles.emitting = true
	if splinter_particles:
		splinter_particles.emitting = true

	await get_tree().create_timer(1.8).timeout
	queue_free()
