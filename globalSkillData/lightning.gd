extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const LIGHTNING_SCENE = preload("res://globalSkillData/lightning.tscn")

var lightningLongPX:int  = 95 # px

var enemy_manager: Node2D # 更通用的管理器变量名，可外部设置
var is_setup: bool = false
var target_enemy: Node2D # 记录当前的终点敌人
var last_target_pos: Vector2 # 记录终点位置，防止敌人消失

func _ready() -> void:
	# 尝试通过分组获取管理器（向后兼容）
	if not enemy_manager:
		var manager_nodes = get_tree().get_nodes_in_group("BT-7271")
		if manager_nodes.size() > 0:
			enemy_manager = manager_nodes[0]
	
	if animated_sprite_2d:
		animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	
	play_lightning()

## 设置敌人管理器（可选，外部调用时可减少耦合）
func set_enemy_manager(manager: Node2D):
	enemy_manager = manager

## 设置闪电。参数可以是 Node2D 或 Vector2,外部调用记得移除BT-7271管理器中的敌人
func setup_lightning(from, to):
	var pos1: Vector2
	var pos2: Vector2
	
	if from is Vector2:
		pos1 = from
	elif from is Node2D and is_instance_valid(from):
		pos1 = from.global_position
	else:
		is_setup = false
		return

	if to is Vector2:
		pos2 = to
		target_enemy = null
	elif to is Node2D and is_instance_valid(to):
		pos2 = to.global_position
		target_enemy = to
	else:
		is_setup = false
		return
	
	last_target_pos = pos2
	global_position = pos1
	
	var diff = pos2 - pos1
	rotation = diff.angle()
	scale.x = diff.length() / lightningLongPX
	scale.y = 1.0
	
	is_setup = true

func play_lightning():
	if not is_setup:
		push_warning("Lightning animation attempted to play before setup!")
		queue_free()
		return
	
	if animated_sprite_2d:
		animated_sprite_2d.play()

func _on_animation_finished():
	spawn_next_lightning()
	queue_free() # 播放完销毁自己

func spawn_next_lightning():
	if not enemy_manager:
		return
	
	# 获取管理器中的敌人数组，支持通过方法或直接访问属性
	var enemy_array = null
	if enemy_manager.has_method("get_lightning_buff_manager"):
		enemy_array = enemy_manager.get_lightning_buff_manager()
	elif enemy_manager.get("lightningBuffManger"):
		enemy_array = enemy_manager.lightningBuffManger
	
	if not enemy_array or enemy_array.size() == 0:
		return
	
	# 确定起点位置
	var start_pos = last_target_pos
	if is_instance_valid(target_enemy):
		start_pos = target_enemy.global_position
	
	# 寻找距离起点最近的敌人
	var nearest_enemy: Node2D = null
	var min_distance = INF
	
	for enemy in enemy_array:
		if not is_instance_valid(enemy):
			continue
		var distance = start_pos.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	if nearest_enemy:
		# 从管理器中移除已选中的敌人（检查方法是否存在）
		if enemy_manager.has_method("removeFromLightningBuffManger"):
			enemy_manager.removeFromLightningBuffManger(nearest_enemy)
		elif enemy_manager.has_method("remove_enemy"):
			enemy_manager.remove_enemy(nearest_enemy)
		
		# 创建新的闪电（使用预加载的场景）
		var new_lightning = LIGHTNING_SCENE.instantiate()
		# 使用最后确定的有效位置作为新闪电的起点
		new_lightning.setup_lightning(last_target_pos, nearest_enemy)
		new_lightning.set_enemy_manager(enemy_manager) # 传递管理器给新闪电
		get_parent().add_child(new_lightning)
