extends "res://skill/scene/skill.gd"

var upgrade_count: int = 0
var base_explosion_radius: float = 100.0

func _ready() -> void:
	super ()

func _skillEmit(_dic: Dictionary = {}):
	await super (_dic)
	
	var mine_scene = load("res://globalSkillData/mine_entity.tscn")
	var level_manager = get_tree().get_first_node_in_group("level") # 假设在 level 组
	var player = get_tree().get_first_node_in_group("player")
	
	# 计算爆炸半径：每级提升 20px
	var current_explosion_radius = base_explosion_radius + (upgrade_count * 20.0)
	
	if _dic.has("fiveCombo"):
		# 奖励分支：在刷怪路径（地图边缘）排布 5 枚地雷
		var spawn_points = []
		if level_manager and level_manager.has_method("get_spawn_points"):
			spawn_points = level_manager.get_spawn_points()
		
		for i in range(5):
			var mine = mine_scene.instantiate()
			mine.explosion_radius = current_explosion_radius
			var pos = Vector2.ZERO
			if spawn_points.size() > 0:
				pos = spawn_points[randi() % spawn_points.size()] + Vector2(randf_range(-50, 50), randf_range(-50, 50))
			else:
				# 保底逻辑：屏幕上方边缘
				pos = Vector2(randf_range(100, 1000), 50)
			
			get_tree().current_scene.add_child(mine)
			mine.global_position = pos
			
	elif _dic.has("brokenCombo"):
		# 生存分支：在玩家防线最内侧部署 3 枚高压地雷
		if player:
			for i in range(3):
				var mine = mine_scene.instantiate()
				mine.explosion_radius = current_explosion_radius
				var offset = Vector2.from_angle(randf() * TAU) * randf_range(50, 100)
				get_tree().current_scene.add_child(mine)
				mine.global_position = player.global_position + offset
				mine.damage *= 1.5 # 增加一点伤害
				
	elif _dic.has("APGained"):
		# 资源分支：精英预判
		var enemies = get_tree().get_nodes_in_group("enemy")
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
			# 假设敌人有速度和方向，预判在其前方
			var velocity = Vector2.DOWN * 50 # 默认向下
			if "velocity" in target: velocity = target.velocity
			elif "speed" in target and "direction" in target: velocity = target.direction * target.speed
			
			get_tree().current_scene.add_child(mine)
			mine.global_position = target.global_position + velocity * 1.5 # 预判 1.5 秒后的位置
			
	else:
		# 常规逻辑：随机位置
		var mine = mine_scene.instantiate()
		mine.explosion_radius = current_explosion_radius
		var view_size = get_viewport().get_visible_rect().size
		var random_pos = Vector2(randf_range(100, view_size.x - 100), randf_range(100, view_size.y - 100))
		get_tree().current_scene.add_child(mine)
		mine.global_position = random_pos
