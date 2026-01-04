extends "res://skill/scene/skill.gd"

var upgrade_count: int = 0
var base_explosion_radius: float = 100.0

func _ready() -> void:
	super ()

## 获取敌人前进方向 + 偏移量的位置
## @param enemy: 敌人节点
## @param offset: 偏移距离（像素）
## @return: 敌人前进方向偏移后的位置
func _get_enemy_forward_pos(enemy: Node2D, offset: float = 50.0) -> Vector2:
	# 获取敌人移动方向，如果没有 velocity 则使用朝向玩家的方向
	var direction: Vector2
	
	# 尝试从 velocity 获取方向（Godot 使用 velocity 作为 CharacterBody2D 属性）
	if "velocity" in enemy and enemy.velocity.length() > 0:
		direction = enemy.velocity.normalized()
	elif "direction" in enemy:
		direction = enemy.direction.normalized()
	else:
		# 保底：朝向玩家的方向
		var player = get_tree().get_first_node_in_group("player")
		if player:
			direction = (player.global_position - enemy.global_position).normalized()
		else:
			direction = Vector2.UP # 默认向上
	
	return enemy.global_position + direction * offset

func _skillEmit(_dic: Dictionary = {}):
	await super (_dic)
	
	var mine_scene = load("res://globalSkillData/mine_entity.tscn")
	var level_manager = get_tree().get_first_node_in_group("level") # 假设在 level 组
	var player = get_tree().get_first_node_in_group("player")
	var view_size = get_viewport().get_visible_rect().size
	
	# 计算爆炸半径：每级提升 20px
	var current_explosion_radius = base_explosion_radius + (upgrade_count * 20.0)
	
	# 获取投掷起始位置（如玩家位置，若没有则用屏幕中心）
	var spawn_pos: Vector2
	if player:
		spawn_pos = player.global_position
	else:
		spawn_pos = view_size / 2
	
	# 获取敌人列表
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	if _dic.has("fiveCombo"):
		# 奖励分支：投掷到敌人前进方向 +50px
		for i in range(5):
			var mine = mine_scene.instantiate()
			mine.explosion_radius = current_explosion_radius
			
			var target_pos: Vector2
			if enemies.size() > 0:
				var target_enemy = enemies[randi() % enemies.size()]
				target_pos = _get_enemy_forward_pos(target_enemy, 50.0)
			else:
				# 保底逻辑：屏幕中心前方
				target_pos = view_size / 2 + Vector2(0, 50)
			
			get_tree().current_scene.add_child(mine)
			mine.global_position = spawn_pos  # 设置起始位置
			mine.throw_to(target_pos)  # 执行投掷动画到目标位置
			
	elif _dic.has("brokenCombo"):
		# 生存分支：在玩家防线最内侧部署 3 枚高压地雷
		if player:
			for i in range(3):
				var mine = mine_scene.instantiate()
				mine.explosion_radius = current_explosion_radius
				var offset = Vector2.from_angle(randf() * TAU) * randf_range(50, 100)
				var target_pos = player.global_position + offset
				get_tree().current_scene.add_child(mine)
				mine.global_position = spawn_pos  # 设置起始位置
				mine.throw_to(target_pos)  # 执行投掷动画到目标位置
				mine.damage *= 1.5 # 增加一点伤害
				
	elif _dic.has("APGained"):
		# 资源分支：精英预判
		var elites = []
		for e in enemies:
			if e.has_method("is_elite") and e.is_elite():
				elites.append(e)
		
		if elites.is_empty(): # 如果没有精英，找血最厚的
			enemies.sort_custom(func(a, b): return a.hp > b.hp if "hp" in a else false)
			if enemies.size() > 0: elites.append(enemies[0])

		for target in elites:
			var mine = mine_scene.instantiate()
			mine.explosion_radius = current_explosion_radius
			# 使用统一的获取敌人前进方向方法
			var target_pos = _get_enemy_forward_pos(target, 50.0)
			get_tree().current_scene.add_child(mine)
			mine.global_position = spawn_pos  # 设置起始位置
			mine.throw_to(target_pos)  # 执行投掷动画到目标位置
			
	else:
		# 常规逻辑：获取一名敌人位置的前进方向 +50px 偏移做投掷位置
		var mine = mine_scene.instantiate()
		mine.explosion_radius = current_explosion_radius
		
		var target_pos: Vector2
		if enemies.size() > 0:
			var target_enemy = enemies[randi() % enemies.size()]
			target_pos = _get_enemy_forward_pos(target_enemy, 50.0)
		else:
			# 保底逻辑：屏幕中心前方
			target_pos = view_size / 2 + Vector2(0, 50)
		
		get_tree().current_scene.add_child(mine)
		mine.global_position = spawn_pos  # 设置起始位置
		mine.throw_to(target_pos)  # 执行投掷动画到目标位置
