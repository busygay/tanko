extends "res://enemy/base_enemy.gd"

# 分裂相关配置
@export var split_count_min: int = 2
@export var split_count_max: int = 3
@export var spawn_radius: float = 75.0
@export var slime_scene: PackedScene  # 史莱姆场景（用于生成新的史莱姆）

# 分裂次数相关
var split_count: int = 1  # 剩余分裂次数，1表示可以分裂一次，0表示不能分裂

func _ready() -> void:
	super()
	# 根据分裂次数设置属性
	apply_slime_properties()
	
	# 如果没有设置史莱姆场景，尝试加载
	if not slime_scene:
		slime_scene = load("res://enemy/slime.tscn")

# 根据分裂次数应用不同的属性
func apply_slime_properties():
	if split_count > 0:
		# 主史莱姆属性
		damage = 2
		attCd = 3
	else:
		# 小史莱姆属性
		damage = min (1,damage/2.0)
		attCd = 3
		self.scale = baseScale * 0.5

# 重写initData方法以支持史莱姆的初始化
func initData(Mul: float):
	super(Mul)
	# 对于从Level系统生成的史莱姆，默认设置为可以分裂一次
	if split_count == 1:  # 如果是初始值
		init_slime(1, health, damage, speed)

# 初始化史莱姆，设置分裂次数和继承属性
func init_slime(remaining_splits: int, parent_health: int = 0, parent_damage: int = 0, parent_speed: int = 0):
	split_count = remaining_splits
	
	if parent_health > 0:
		# 继承父史莱姆的属性
		if split_count > 0:
			# 如果还能分裂，使用标准属性
			health = int(parent_health * 0.5)
			damage = int(parent_damage * 0.5)
			speed = int(parent_speed * 1.5)
		else:
			# 如果不能分裂了，使用小史莱姆属性
			health = int(parent_health * 0.5)
			damage = int(parent_damage * 0.5)
			speed = int(parent_speed * 1.5)
	
	apply_slime_properties()

# 重写死亡方法以实现分裂机制
func die():
	if split_count > 0:
		spawn_small_slimes()
	super.die()

# 生成小史莱姆
func spawn_small_slimes():
	if not slime_scene:
		push_error("史莱姆场景未设置！")
		return
	var spawn_count = randi_range(split_count_min, split_count_max)
	for i in spawn_count:
		var new_slime = slime_scene.instantiate()
		var angle = (PI * 2 * i) / spawn_count + randf_range(-0.5, 0.5)
		var distance = randf_range(spawn_radius * 0.5, spawn_radius)
		var offset = Vector2(cos(angle) * distance, sin(angle) * distance)
		new_slime.global_position = global_position + offset
		get_tree().current_scene.add_child(new_slime)
		# 等待下一帧再初始化，确保_ready()已经执行
		new_slime.init_slime(split_count - 1, health, damage, speed)

		
