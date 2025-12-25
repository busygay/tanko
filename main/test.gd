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
			# Remove the entire popup container (not just the enemy_list)
			tempscroll.queue_free()
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
			# Remove the entire popup container (not just the skill_list)
			tempscroll.queue_free()
		)
		skill_list.add_child(button)
		


func _on_add_levels_pressed() -> void:
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

	var level_list = VBoxContainer.new()
	tempscroll.add_child(level_list)
	
	# Get reference to Level singleton
	var level = get_node("/root/Level")
	
	# Create buttons for adding levels
	var level_increments = [1, 3, 5, 10]
	for increment in level_increments:
		var button = Button.new()
		button.text = "增加关卡 +%d" % increment
		button.pressed.connect(func():
			# Log the level increase
			print("增加关卡前：", level.currentLevel, "，增加：", increment)
			
			# 清理现有敌人
			if not level.memEnemys.is_empty():
				print("清理现有敌人，数量：", level.memEnemys.size())
				for i in level.memEnemys:
					if is_instance_valid(i):
						i.queue_free()
				level.memEnemys.clear()
			
			# 重置关卡状态
			level.enemysSpanwFinish.clear()
			print("已重置关卡状态：enemysSpanwFinish")
			
			# Increase current level by increment
			level.currentLevel += increment
			print("增加关卡后：", level.currentLevel)
			
			# 可选：调用enterLevel来正确初始化新关卡
			level.enterLevel()
			print("已调用enterLevel()初始化新关卡")
			
			# Remove the entire popup container (not just the level_list)
			tempscroll.queue_free()
		)
		level_list.add_child(button)


func _on_emit_skill_pressed() -> void:
	var existing_scroll = get_node_or_null("../tempScroll")
	if existing_scroll:
		existing_scroll.free()
	
	var tempscroll = ScrollContainer.new()
	tempscroll.custom_minimum_size = Vector2(300,400)
	tempscroll.scale = Vector2(3,3)
	var tempPos:Vector2 = Vector2(self.size.x*scale.x +10,0)
	tempscroll.global_position=tempPos
	tempscroll.name = "tempScroll"
	tempscroll.process_mode = Node.PROCESS_MODE_ALWAYS
	get_parent().add_child(tempscroll)
	
	var button_list = VBoxContainer.new()
	tempscroll.add_child(button_list)
	
	# 创建 "emitAllSkill" 按钮
	var emit_all_skill_button = Button.new()
	emit_all_skill_button.text = "发射所有技能 (emitAllSkill)"
	emit_all_skill_button.pressed.connect(func():
		_emit_all_skill()
		tempscroll.queue_free()
	)
	button_list.add_child(emit_all_skill_button)
	
	# 创建 "emitAllSkillTigger" 按钮
	var emit_all_skill_tigger_button = Button.new()
	emit_all_skill_tigger_button.text = "触发所有技能触发器 (emitAllSkillTigger)"
	emit_all_skill_tigger_button.pressed.connect(func():
		_emit_all_skill_tigger()
		tempscroll.queue_free()
	)
	button_list.add_child(emit_all_skill_tigger_button)


# 发射所有技能
func _emit_all_skill():
	var tigger_node = get_tree().get_first_node_in_group("tigger")
	if not tigger_node:
		print("无法获取 tigger 节点")
		return
	
	# 获取所有已装备和未装备的技能
	var all_skills = []
	
	# 1. 添加未装备的技能（在 unequip 数组中）
	if tigger_node.has_method("_returnUnequip"):
		all_skills.append_array(tigger_node._returnUnequip())
	
	# 2. 添加已装备的技能
	# tigger_node.tigger 是一个字典，结构如下：
	# {
	#     "onCombo": $onComboTigger,
	#     "twoCombo": $twoComboTigger,
	#     "fiveCombo": $fiveComboTigger,
	#     ...
	# }
	# 每个 value (如 $onComboTigger) 是一个容器节点，存放着装备到该触发器的技能
	var tigger_dict = tigger_node.get("tigger")
	if tigger_dict:
		for tigger_name in tigger_dict:
			var tigger_container = tigger_dict[tigger_name]  # 获取触发器容器
			if tigger_container:
				all_skills.append_array(tigger_container.get_children())  # 添加容器中的所有技能节点
	
	# 对每个技能调用 _skillEmit
	for skill_node in all_skills:
		if is_instance_valid(skill_node) and skill_node.has_method("_skillEmit"):
			print("发射技能:", skill_node)
			skill_node._skillEmit.call_deferred()


# 触发所有技能触发器
func _emit_all_skill_tigger():
	# 触发所有技能触发器的 Emit 信号
	Eventmanger.onComboEmit.emit()
	Eventmanger.twoComboEmit.emit()
	Eventmanger.fiveComboEmit.emit()
	Eventmanger.brokenComboEmit.emit()
	Eventmanger.APGainedEmit.emit()
	Eventmanger.APSpentEmit.emit()
	
	print("已触发所有技能触发器")
