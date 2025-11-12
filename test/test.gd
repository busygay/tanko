extends Node2D

const PLAYER_SCENE = preload("res://main/player.tscn")

func _on_next_level_button_pressed() -> void:
	pass # Replace with function body.


func _on_add_enemy_button_pressed() -> void:
	pass # Replace with function body.


func _on_creat_player_pressed() -> void:
	# 检查是否已经有玩家存在，避免重复创建
	if get_tree().get_first_node_in_group("players"):
		print("Player already exists.")
		return
		
	# 实例化玩家场景
	var player_instance = PLAYER_SCENE.instantiate()
	
	# 将玩家放置在屏幕正中间
	player_instance.global_position = get_viewport_rect().size / 2
	
	# 将玩家实例添加到场景树中
	add_child(player_instance)


func _on_player_level_up_button_pressed() -> void:
	pass # Replace with function body.


func _on_get_new_skill_button_pressed() -> void:
	pass # Replace with function body.
