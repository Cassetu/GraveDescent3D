class_name PauseMenu
extends CanvasLayer

@export var show_save_button: bool = true

@onready var exit_confirm: ConfirmationDialog = %ExitConfirmDialog

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	%SaveButton.visible = show_save_button
	%SaveButton.pressed.connect(_on_save_pressed)
	%SaveQuitButton.pressed.connect(_on_exit_button_pressed)
	%OptionsButton.pressed.connect(_on_options_pressed)
	%ReturnButton.pressed.connect(_close)
	exit_confirm.confirmed.connect(_on_exit_confirm_dialog_confirmed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_close()
			get_viewport().set_input_as_handled()
		elif not _other_menu_open():
			_open()
			get_viewport().set_input_as_handled()

func _other_menu_open() -> bool:
	for menu in get_tree().get_nodes_in_group("blocking_menu"):
		if menu.visible:
			return true
	return false

func _open() -> void:
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close() -> void:
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_save_pressed() -> void:
	GameManager.save()

func _on_exit_button_pressed() -> void:
	exit_confirm.popup_centered()

func _on_exit_confirm_dialog_confirmed() -> void:
	GameManager.load_save()
	_close()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_options_pressed() -> void:
	pass
