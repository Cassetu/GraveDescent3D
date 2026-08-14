class_name LetterPanel
extends Control

signal continued

@onready var text_label: Label = %TextLabel
@onready var signature_label: Label = %SignatureLabel
@onready var continue_button: Button = %ContinueButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.grab_focus()

func setup(letter_text: String, signature: String) -> void:
	text_label.text = letter_text
	signature_label.text = signature

func _on_continue_pressed() -> void:
	continued.emit()
	queue_free()
