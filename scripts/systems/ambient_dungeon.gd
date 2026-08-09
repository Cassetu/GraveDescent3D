extends Node

@export var ambient_sounds: Array[AudioStream] = []
@export var min_interval: float = 20.0
@export var max_interval: float = 45.0

var _players: Array[AudioStreamPlayer] = []
var _timers: Array[Timer] = []

func _ready() -> void:
	if ambient_sounds.size() == 0:
		push_warning("AmbientManager: No sounds added to the list!")
		return
		
	for i in range(ambient_sounds.size()):
		var sound = ambient_sounds[i]
		
		var p = AudioStreamPlayer.new()
		p.stream = sound
		add_child(p)
		_players.append(p)
		
		var t = Timer.new()
		t.one_shot = true
		add_child(t)
		_timers.append(t)
		
		t.timeout.connect(func(): _on_sound_timer_timeout(i))
		
		_start_random_timer(i)

func _start_random_timer(index: int) -> void:
	var random_time := randf_range(min_interval, max_interval)
	_timers[index].start(random_time)

func _on_sound_timer_timeout(index: int) -> void:
	var player = _players[index]
	
	if not player.playing:
		player.pitch_scale = randf_range(0.9, 1.1)
		player.play()
		print("[AMBIENT] Playing sound index: ", index, " - ", player.stream.resource_path.get_file())
		
	_start_random_timer(index)
