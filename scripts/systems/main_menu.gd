extends CanvasLayer

@onready var continue_btn: Button = %ContinueButton

func _ready() -> void:
	continue_btn.disabled = GameManager.player_current_hp == -1

func _on_new_run_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/base.tscn")

func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/base.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
