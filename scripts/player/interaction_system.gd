class_name InteractionSystem
extends Node

@export var reach: float = 2.5
@export var outline_width: float = 0.02

var _camera: Camera3D
var _current: Interactable = null
var _outline_mat: ShaderMaterial

func _ready() -> void:
	_camera = get_viewport().get_camera_3d()
	_outline_mat = ShaderMaterial.new()
	_outline_mat.shader = load("res://resources/shaders/outline.gdshader")
	_outline_mat.set_shader_parameter("outline_width", outline_width)

func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	var hit := _raycast()
	var found: Interactable = null

	if hit and hit.collider:
		found = _find_interactable(hit.collider)

	if found != _current:
		_set_outline(_current, false)
		_current = found
		_set_outline(_current, true)
		get_node("/root/InteractionUI").update(_current.get_prompt() if _current else "")

	if _current and Input.is_action_just_pressed("interact"):
		_current.interact(get_parent())
		InteractionUI.update("")
		_current = null

func _raycast() -> Dictionary:
	var origin := _camera.global_position
	var forward := -_camera.global_basis.z
	var space: PhysicsDirectSpaceState3D = get_parent().get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * reach)
	query.exclude = [get_parent().get_rid()]
	return space.intersect_ray(query)

func _find_interactable(node: Node) -> Interactable:
	var n := node
	while n != null:
		if n is Interactable:
			return n as Interactable
		n = n.get_parent()
	return null

func _set_outline(target: Interactable, on: bool) -> void:
	if not target:
		return
	var mesh := target.get_node_or_null("Mesh") as MeshInstance3D
	if not mesh:
		return
	var mat := mesh.get_active_material(0)
	if mat:
		mat.next_pass = _outline_mat if on else null
