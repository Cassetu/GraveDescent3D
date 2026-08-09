extends Node

signal souls_changed(new_amount: int)
signal shards_changed(new_amount: int)
signal hp_changed(new_hp: int, max_hp: int)
var fade_in_on_load: bool = false
var souls: int = 0
var unlocked_upgrades: Array[String] = []
var player_current_hp: int = -1
var player_current_stamina: float = -1.0
var shards: int = 0
var current_depth: int = 1
var player_max_hp: int = 100
var player_damage_bonus: int = 0

func _ready() -> void:
	load_save()
	#reset_save() #TODO: DELETE WHEN PUBLIsh GAME 
	#print("Reset Save Complete")
	
func add_souls(amount: int) -> void:
	souls += amount
	souls_changed.emit(souls)

func add_shards(amount: int) -> void:
	shards += amount
	shards_changed.emit(shards)

func spend_souls(amount: int) -> bool:
	if souls < amount:
		return false
	souls -= amount
	souls_changed.emit(souls)
	return true

func spend_shards(amount: int) -> bool:
	if shards < amount:
		return false
	shards -= amount
	shards_changed.emit(shards)
	return true

func on_player_died() -> void:
	shards = 0
	current_depth = 1
	player_current_hp = -1
	player_current_stamina = -1.0
	shards_changed.emit(shards)
	get_tree().change_scene_to_file("res://scenes/base.tscn")

func on_run_started() -> void:
	shards = 0
	current_depth = 1
	player_current_hp = -1
	player_current_stamina = -1.0

func save() -> void:
	var data := {
		"souls": souls,
		"unlocked_upgrades": unlocked_upgrades,
		"player_max_hp": player_max_hp,
		"player_damage_bonus": player_damage_bonus,
		"player_current_hp": player_current_hp,
		"player_current_stamina": player_current_stamina,
	}
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_save() -> void:
	if not FileAccess.file_exists("user://save.json"):
		return
	var file := FileAccess.open("user://save.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	souls = data.get("souls", 0)
	var raw: Array = data.get("unlocked_upgrades", [])
	unlocked_upgrades = Array(raw, TYPE_STRING, "", null)
	player_max_hp = data.get("player_max_hp", 100)
	player_damage_bonus = data.get("player_damage_bonus", 0)
	player_current_hp = data.get("player_current_hp", -1)
	player_current_stamina = data.get("player_current_stamina", -1.0)
func reset_save() -> void:
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute(OS.get_user_data_dir() + "/save.json")
	souls = 0
	shards = 0
	unlocked_upgrades.clear()
	player_max_hp = 100
	player_damage_bonus = 0
	player_current_hp = -1
	player_current_stamina = -1.0
func save_player_state(hp: int, stamina: float) -> void:
	player_current_hp = hp
	player_current_stamina = stamina
func apply_upgrade(id: String) -> void:
	match id:
		"max_hp":
			player_max_hp += 20
		"damage":
			player_damage_bonus += 5
		"roll_cooldown":
			pass
		"move_speed":
			pass

func get_roll_cooldown() -> float:
	var base := 0.9
	var reduction := unlocked_upgrades.count("roll_cooldown") * 0.1
	return max(0.3, base - reduction)

func get_move_speed() -> float:
	var base := 5.0
	return base + unlocked_upgrades.count("move_speed") * 0.5
