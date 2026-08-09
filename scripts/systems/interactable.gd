class_name Interactable
extends Node3D

@export var prompt_text: String = "Interact"

func interact(player: Node) -> void:
	pass

func get_prompt() -> String:
	return "[E] " + prompt_text
