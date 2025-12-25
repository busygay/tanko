extends Node2D
@onready var node_2d: Node2D = $Node2D

const LIGHTNING_SCENE = preload("res://globalSkillData/lightning.tscn")

var master: Node # 用于获取父级 BT-7271


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 获取 master (BT-7271)
	if not master:
		var manager_nodes = get_tree().get_nodes_in_group(&"BT-7271")
		if manager_nodes.size() > 0:
			master = manager_nodes[0]
	
	# 使用 tween 在 0.5 秒中放大 node_2d 并设置透明度为一半
	var tween = create_tween()
	tween.parallel().tween_property(node_2d, "scale", Vector2(3.0, 3.0), 0.5)
	tween.parallel().tween_property(node_2d, "modulate:a", 0.5, 0.5)
	tween.parallel().tween_callback(func(): queue_free()).set_delay(0.5)
	
	# 0.3 秒后创建 lightning
	if master:
		get_tree().create_timer(0.3).timeout.connect(func(): _spawn_lightning())


# 设置 master (BT-7271)
func set_master(_master: Node):
	master = _master


# 创建 lightning
func _spawn_lightning():
	if not master or master.lightningBuffManger.size() == 0:
		return
	
	# 寻找距离最近的敌人
	var nearest_enemy: Node2D = null
	var min_distance = INF
	
	for enemy in master.lightningBuffManger:
		if not is_instance_valid(enemy):
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	if not is_instance_valid(nearest_enemy):
		return
	
	var lightning = LIGHTNING_SCENE.instantiate()
	lightning.setup_lightning(global_position, nearest_enemy)
	lightning.set_enemy_manager(master)
	
	# 从 lightningBuffManger 中移除目标敌人
	if master.has_method("removeFromLightningBuffManger"):
		master.removeFromLightningBuffManger(nearest_enemy)
	
	get_parent().add_child(lightning)
