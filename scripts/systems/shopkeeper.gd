class_name Shopkeeper
extends Interactable

func _ready() -> void:
	prompt_text = "Open Shop"

@onready var menu: ShopMenu = get_tree().get_first_node_in_group("shop_menu")

func interact(player: Node) -> void:
	menu.open()
