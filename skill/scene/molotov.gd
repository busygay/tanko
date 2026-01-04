extends "res://skill/scene/skill.gd"

var molotov_scene = preload("res://globalSkillData/molotov_entity.tscn")

func _ready() -> void:
	super ()

func _skillEmit(_dic: Dictionary = {}):
	await super ()
	
	var pos_array: Array = []
	var view_size = get_viewport_rect().size
	var player = get_tree().get_first_node_in_group("player")
	var center_pos = _get_center_pos(player, view_size)
	var spawn_pos = _get_spawn_pos(player, view_size)

	if _dic.has("fiveCombo"):
		print("执行金黄色长效火墙逻辑")
		pos_array = _generate_fire_wall_positions(view_size)
			
	elif _dic.has("brokenCombo"):
		print("执行环形火焰保护圈逻辑")
		pos_array = _generate_fire_ring_positions(center_pos)
			
	elif _dic.has("APSpent"):
		print("执行高能蓝火逻辑")
		pos_array = _generate_targeted_positions(view_size)
		
	else:
		print("执行常规随机火海逻辑")
		pos_array = _generate_targeted_positions(view_size)
	
	print("Molotov positions:", pos_array)
	
	_spawn_molotovs(spawn_pos, pos_array)

# 获取中心位置
func _get_center_pos(player: Node2D, view_size: Vector2) -> Vector2:
	if player:
		return player.global_position
	return view_size / 2

# 获取投掷起始位置
func _get_spawn_pos(player: Node2D, view_size: Vector2) -> Vector2:
	if player:
		return player.global_position
	return view_size / 2

# 生成火墙位置（五连击）
func _generate_fire_wall_positions(view_size: Vector2) -> Array:
	var pos_array: Array = []
	var center = _get_random_enemy_or_random_pos(view_size)
	var y_pos = center.y
	var x_offset = 200.0
	var start_x = center.x - x_offset * 2
	var step = x_offset
	for i in range(5):
		pos_array.append(Vector2(start_x + i * step, y_pos))
	return pos_array

# 生成环形火焰保护圈位置（断连击）
func _generate_fire_ring_positions(center_pos: Vector2) -> Array:
	var pos_array: Array = []
	var radius = 150.0
	for i in range(5):
		var angle = i * (TAU / 5.0)
		var offset = Vector2(cos(angle), sin(angle)) * radius
		pos_array.append(center_pos + offset)
	return pos_array

# 获取随机敌人位置，如果没有敌人则返回随机位置
func _get_random_enemy_or_random_pos(view_size: Vector2) -> Vector2:
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	if not enemies.is_empty():
		var target = enemies[randi() % enemies.size()]
		return target.global_position
	
	return _get_random_pos(view_size)

# 生成随机位置（保底方案）
func _get_random_pos(view_size: Vector2) -> Vector2:
	var padding = 50.0
	return Vector2(
		randf_range(padding, view_size.x - padding),
		randf_range(padding, view_size.y - padding)
	)

# 生成带索敌的目标位置
func _generate_targeted_positions(view_size: Vector2) -> Array:
	var pos_array: Array = []
	pos_array.append(_get_random_enemy_or_random_pos(view_size))
	return pos_array

# 生成并投掷燃烧瓶
func _spawn_molotovs(spawn_pos: Vector2, pos_array: Array):
	for target_pos in pos_array:
		var molotov = molotov_scene.instantiate()
		get_tree().current_scene.add_child(molotov)
		molotov.global_position = spawn_pos
		molotov.throw_to(target_pos)
