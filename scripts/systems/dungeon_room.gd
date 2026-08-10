class_name DungeonRoom
extends Node3D

signal room_exited(to_next_depth: bool)
#for: use area3D and coll, inspector add (metadata) key "goes_deeper", value true/false
func _ready() -> void:
	for exit in find_children("*", "Area3D"):
		if exit.is_in_group("room_exit"):
			exit.body_entered.connect(func(body): _on_exit_entered(body, exit))
			print("connected exit: ", exit.name)

func _on_exit_entered(body: Node3D, exit: Node3D) -> void:
	print("exit entered by: ", body.name)
	if not body is Player:
		return
	var goes_deeper: bool = exit.get_meta("goes_deeper", false)
	print("goes_deeper: ", goes_deeper)
	room_exited.emit(goes_deeper)
