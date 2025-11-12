extends VBoxContainer


func _ready() -> void:
		###test mode
	if globalSet.isTestMode:
		self.show()
	else:
		self.add_to_group("popup")
		self.hide()

func _on_player_level_up_button_pressed() -> void:
	var existing_scroll = get_node_or_null("../tempScroll")
	if existing_scroll:
		existing_scroll.free()
	var main = get_tree().get_root().get_node_or_null("main")
	if main:
		# Trigger the level up by setting the current experience to the required amount
		main.currentExp = main.NextLevelExp


func _on_add_enemy_button_pressed() -> void:
	var tempscroll = ScrollContainer.new()
	tempscroll.custom_minimum_size = Vector2(300,400)
	tempscroll.scale = Vector2(3,3)
	var tempPos:Vector2 = Vector2(self.size.x*scale.x +10,0)
	tempscroll.global_position=tempPos
	tempscroll.name = "tempScroll"
	tempscroll.process_mode = Node.PROCESS_MODE_ALWAYS
	var existing_scroll = get_node_or_null("../tempScroll")
	if existing_scroll:
		existing_scroll.free()
	get_parent().add_child(tempscroll)

	var enemy_list = VBoxContainer.new()

	tempscroll.add_child(enemy_list)
	
	# Get reference to Level singleton
	var level = get_node("/root/Level")
	
	# Create buttons for each enemy type
	for enemy_name in level.enemys.keys():
		var button = Button.new()
		button.text = enemy_name
		button.pressed.connect(func():
			var enemy = level.enemys[enemy_name].instantiate()
			enemy.position = level.getrandipos()
			enemy.initData(1.0)
			get_tree().get_first_node_in_group("main").add_child(enemy)
			level.memEnemys.append(enemy)
			enemy_list.queue_free()
		)
		enemy_list.add_child(button)


func _on_invincible_mode_button_pressed() -> void:
	var existing_scroll = get_node_or_null("../tempScroll")
	if existing_scroll:
		existing_scroll.free()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.MaxHealth = 99999
		player.health = 99999
		player.baseDamage = 99999


func _on_get_skill_button_pressed() -> void:
	var tempscroll = ScrollContainer.new()
	tempscroll.custom_minimum_size = Vector2(300,400)
	tempscroll.scale = Vector2(3,3)
	var tempPos:Vector2 = Vector2(self.size.x*scale.x +10,0)
	tempscroll.global_position=tempPos
	tempscroll.name = "tempScroll"
	tempscroll.process_mode = Node.PROCESS_MODE_ALWAYS
	var existing_scroll = get_node_or_null("../tempScroll")
	if existing_scroll:
		existing_scroll.free()
	get_parent().add_child(tempscroll)
	var skill_list = VBoxContainer.new()
	skill_list.name = "SkillList"
	skill_list.process_mode = Node.PROCESS_MODE_ALWAYS
	tempscroll.add_child(skill_list)
	
	# 为每个技能创建一个按钮
	
	for skill_data in SkillManager._skillDataCopy.values():
		var button = Button.new()
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		# 假设技能数据中有 `name` 属性用于显示
		button.text = skill_data.skill_cname
		button.pressed.connect(func():
			var shop = get_node("../shoping")
			get_tree().paused = true
			# 清除商店中现有的技能选项
			shop.clearSkillRow()
			
			# 手动将选择的技能添加到商店的第一个槽位
			var skill_row_scene = preload("res://shop/skillrow.tscn")
			var skill_row_instance = skill_row_scene.instantiate()
			shop.h_box_container.get_child(0).add_child(skill_row_instance)
			skill_row_instance._setData(skill_data)
			
			# 显示商店（模仿 shop.showShoping 的逻辑，但不随机化技能）
			Eventmanger.UIHideAll.emit(shop)
			shop.isLevelDone = false
			shop.show()
			
			# 移除技能选择列表
			skill_list.queue_free()
		)
		skill_list.add_child(button)
		
