extends CanvasLayer

@onready var continue_btn: Button = %ContinueButton
@onready var new_run_confirm: ConfirmationDialog = %NewRunConfirmDialog

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	continue_btn.disabled = not FileAccess.file_exists("user://save.json")

func _on_new_run_button_pressed() -> void:
	if FileAccess.file_exists("user://save.json"):
		new_run_confirm.popup_centered()
	else:
		_start_new_run()

func _on_new_run_confirm_dialog_confirmed() -> void:
	_start_new_run()

func _start_new_run() -> void:
	GameManager.reset_save()
	GameManager.save()
	get_tree().change_scene_to_file("res://scenes/base.tscn")

func _on_continue_button_pressed() -> void:
	if GameManager.in_dungeon_run:
		get_tree().change_scene_to_file("res://scenes/levels/dungeon_runner.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/base.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
