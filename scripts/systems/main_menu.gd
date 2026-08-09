extends CanvasLayer

@onready var continue_btn: Button = %ContinueButton
@onready var new_run_confirm: ConfirmationDialog = %NewRunConfirmDialog

func _ready() -> void:
	continue_btn.disabled = GameManager.player_current_hp == -1

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
	get_tree().change_scene_to_file("res://scenes/base.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
