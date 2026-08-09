class_name UpgradeAltar
extends Interactable

func _ready() -> void:
	prompt_text = "Open Upgrades"

@onready var menu: UpgradeMenu = get_node("/root/Base/UpgradeMenu")

func interact(player: Node) -> void:
	menu.open()
