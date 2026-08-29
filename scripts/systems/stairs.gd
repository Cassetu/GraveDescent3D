@tool
class_name Stairs
extends Node3D

@export var step_count: int = 12:
	set(v):
		step_count = max(v, 1)
		_regenerate()
@export var step_rise: float = 0.2:
	set(v):
		step_rise = max(v, 0.01)
		_regenerate()
@export var step_run: float = 0.3:
	set(v):
		step_run = max(v, 0.01)
		_regenerate()
@export var step_width: float = 1.2:
	set(v):
		step_width = max(v, 0.1)
		_regenerate()
@export var step_material: Material = preload("res://resources/materials/floor.tres"):
	set(v):
		step_material = v
		_regenerate()
@export var regenerate_now: bool = false:
	set(v):
		regenerate_now = v
		_regenerate()
	
func _ready() -> void:
	if Engine.is_editor_hint():
		_regenerate()

func _regenerate() -> void:
	if not Engine.is_editor_hint():
		return
	if not is_inside_tree():
		return
	for child in get_children():
		child.queue_free()
	for i in range(step_count):
		var box := CSGBox3D.new()
		var height := step_rise * (i + 1)
		var depth := step_run * (step_count - i)
		box.size = Vector3(step_width, height, depth)
		box.position = Vector3(0.0, height * 0.5, i * step_run + depth * 0.5)
		box.use_collision = true
		box.material_override = step_material
		add_child(box)
		box.owner = get_tree().edited_scene_root
