class_name DungeonRunner
extends Node3D

@export var depth: int = 1
@export var rooms_until_boss: int = 3

var _rooms_completed: int = 0
var _current_room: Node3D = null
var _player: Player = null
var _is_transitioning: bool = false

var _visited_rooms: Array[String] = []

func _ready() -> void:	
	_player = preload("res://scenes/player.tscn").instantiate()
	add_child(_player)
	_load_random_room()

func _load_random_room() -> void:
	if _current_room:
		_current_room.queue_free()
		_current_room = null

	var room_scene: PackedScene

	if _rooms_completed >= rooms_until_boss:
		room_scene = _pick_boss_room()
	else:
		room_scene = _pick_random_room(depth)

	if not room_scene:
		push_error("DungeonRunner: no room found for depth %d" % depth)
		return

	_current_room = room_scene.instantiate()
	add_child(_current_room)
	
	var spawn := _current_room.get_node_or_null("SpawnPoint") as Node3D
	if spawn:
		_player.global_position = spawn.global_position
		_player.global_rotation = spawn.global_rotation
			
	if _current_room.has_signal("room_exited"):
		_current_room.room_exited.connect(_on_room_exited)

func _pick_random_room(target_depth: int) -> PackedScene:
	var path := "res://scenes/levels/depth_%d/" % target_depth
	var dir := DirAccess.open(path)
	if not dir:
		push_error("DungeonRunner: folder not found — %s" % path)
		return null

	var files: Array[String] = []
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.ends_with(".tscn") or file.ends_with(".tscn.remap"):
			var clean_file = file.trim_suffix(".remap")
			var full_path = path + clean_file
			
			if not _visited_rooms.has(full_path):
				files.append(full_path)
				
		file = dir.get_next()
	dir.list_dir_end()

	if files.is_empty():
		_visited_rooms.clear()
		return _pick_random_room(target_depth)

	files.shuffle()
	var selected_room_path = files[0]
	
	_visited_rooms.append(selected_room_path)
	
	return ResourceLoader.load(selected_room_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene

func _pick_boss_room() -> PackedScene:
	var path := "res://scenes/levels/boss_%d.tscn" % depth
	if ResourceLoader.exists(path):
		return load(path) as PackedScene
	push_error("DungeonRunner: boss room not found — %s" % path)
	return null

func _on_room_exited(to_next_depth: bool) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
	if _player:
		_player.restore_stamina(_player.max_stamina)
		_player.save_state()
	_rooms_completed += 1
	
	if to_next_depth:
		depth += 1
		_rooms_completed = 0
		_visited_rooms.clear()
		
	_fade_transition()

func _fade_transition() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var overlay := ColorRect.new()
	overlay.color = Color.BLACK
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.modulate.a = 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.35)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_load_random_room)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		canvas.queue_free()
		_is_transitioning = false 
	)

func player_died() -> void:
	GameManager.save()
	GameManager.on_player_died()
	get_tree().change_scene_to_file("res://scenes/base.tscn")
