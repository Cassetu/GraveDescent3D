class_name DungeonDoor
extends Interactable

func _ready() -> void:
	prompt_text = "Enter Dungeon"

func interact(_player: Node) -> void:
	GameManager.on_run_started()
	GameManager.save(false)
	get_tree().change_scene_to_file("res://scenes/levels/dungeon_runner.tscn")
