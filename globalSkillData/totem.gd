extends Node2D

# 图腾相关属性
@export var speed_multiplier: float = 1.5  # 加速倍数（默认1.5）
@export var buff_duration: float = 5.0  # Buff持续时间（默认5秒）
@export var buff_cooldown: float = 1.0  # Buff应用冷却时间（默认1秒）

# 内部状态
var affected_enemies: Array = []  # 存储当前受影响的敌人列表
var last_buff_time: float = 0.0  # 上次应用Buff的时间
var buff_cooldown_timer: float = 0.0  # 冷却计时器

# Buff视觉效果场景
@export var speed_buff_scene: PackedScene = preload("res://main/speed_buff.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 更新冷却计时器
	if buff_cooldown_timer > 0:
		buff_cooldown_timer -= delta
	
	# 定期重新应用Buff（如果需要）
	if buff_cooldown_timer <= 0 and affected_enemies.size() > 0:
		_reapply_buffs_to_all_enemies()
		buff_cooldown_timer = buff_cooldown


func _on_area_2d_body_entered(body: Node2D) -> void:
	# 检测进入区域的是否为敌人
	if _is_enemy(body):
		# 为敌人应用加速Buff
		if _apply_speed_buff_to_enemy(body):
			# 将敌人添加到受影响列表
			if not affected_enemies.has(body):
				affected_enemies.append(body)
			# 添加视觉效果
			_add_buff_visual_effect(body)


func _on_area_2d_body_exited(body: Node2D) -> void:
	# 从受影响列表中移除敌人
	if affected_enemies.has(body):
		affected_enemies.erase(body)
		# （可选）添加移除视觉效果
		_remove_buff_visual_effect(body)


# 检查对象是否为敌人
func _is_enemy(body: Node2D) -> bool:
	if not is_instance_valid(body):
		return false
	
	# 检查是否有敌人相关的方法或属性
	if body.has_method("apply_buff") and body.has_method("remove_buff"):
		return true
	
	# 检查是否在敌人组中
	if body.is_in_group("enemy"):
		return true
	
	# 检查类名是否包含enemy（不区分大小写）
	if body.get_class().to_lower().contains("enemy"):
		return true
	
	return false


# 为单个敌人应用加速Buff
func _apply_speed_buff_to_enemy(enemy: Node2D) -> bool:
	if not is_instance_valid(enemy):
		return false
	
	# 检查敌人是否有Buff系统支持
	if not enemy.has_method("apply_buff"):
		push_warning("敌人不支持Buff系统:", enemy.name)
		return false
	
	# 创建Buff实例数据
	var buffInstance = {
		"type": "speed",
		"multiplier": speed_multiplier,
		"duration": buff_duration,
		"source": self
	}
	
	# 应用Buff到敌人
	var result = enemy.apply_buff(buffInstance)
	
	if result:
		print("成功为敌人 ", enemy.name, " 应用加速Buff，倍数: ", speed_multiplier)
	
	return result


# 为所有受影响的敌人重新应用Buff
func _reapply_buffs_to_all_enemies() -> void:
	# 清理无效的敌人引用
	_cleanup_invalid_enemies()
	
	# 为每个敌人重新应用Buff
	for enemy in affected_enemies:
		if is_instance_valid(enemy):
			_apply_speed_buff_to_enemy(enemy)


# 清理无效的敌人引用
func _cleanup_invalid_enemies() -> void:
	var valid_enemies = []
	for enemy in affected_enemies:
		if is_instance_valid(enemy):
			valid_enemies.append(enemy)
	affected_enemies = valid_enemies


# 添加Buff视觉效果
func _add_buff_visual_effect(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or not speed_buff_scene:
		return
	
	# 检查是否已存在视觉效果
	if _has_buff_visual_effect(enemy):
		return
	
	# 创建视觉效果实例
	var visual_effect = speed_buff_scene.instantiate()
	if visual_effect:
		# 设置视觉效果位置（在敌人上方）
		visual_effect.global_position = enemy.global_position + Vector2(0, -30)
		# 设置父节点为敌人，这样视觉效果会跟随敌人移动
		enemy.add_child(visual_effect)
		# 应用Buff到敌人
		visual_effect.applyBuff(enemy)
		print("为敌人 ", enemy.name, " 添加视觉效果并应用Buff")


# 移除Buff视觉效果
func _remove_buff_visual_effect(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	
	# 查找并移除敌人的speed_buff子节点
	for child in enemy.get_children():
		if child.get_class() == "Sprite2D" and child.has_method("applyBuff"):
			child.queue_free()
			print("移除敌人 ", enemy.name, " 的视觉效果")
			break


# 检查敌人是否已有Buff视觉效果
func _has_buff_visual_effect(enemy: Node2D) -> bool:
	if not is_instance_valid(enemy):
		return false
	
	for child in enemy.get_children():
		if child.get_class() == "Sprite2D" and child.has_method("applyBuff"):
			return true
	
	return false
