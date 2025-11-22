extends "res://enemy/base_enemy.gd"

# 分裂相关配置
@export var split_times_min: int = 1
@export var split_times_max: int = 3

var split_count_max :int =3 
var split_count_min :int =1

@export var spawn_radius: float = 75.0
@export var slime_scene: PackedScene  # 史莱姆场景（用于生成新的史莱姆）

# 分裂次数
var split_times :int =0 #剩余分裂次数，1表示可以分裂一次，0表示不能分裂

func _ready() -> void:
	baseDir = true
	super()
	# 根据分裂次数设置属性
	# 如果没有设置史莱姆场景，尝试加载



# 重写initData方法以支持史莱姆的初始化
func initData(Mul: float,_initSplit_times:int = -1):
	super(Mul)
	

	#initData一般只有level脚本调用，且不设置_initSplit_times,因此对于该变量为-1的情况继续随机生成
	
	#如果关卡太低，就不要分裂了
	var currentLevel = Level.currentLevel
	
	if currentLevel <5:
		split_times =0
	elif _initSplit_times <= -1 :
		split_times = randi_range(split_times_min,split_times_max)
	
	else:
		split_times = _initSplit_times
		

# 重写死亡方法以实现分裂机制
func die():
	if split_times > 0:
		spawn_small_slimes()
	super.die()

# 生成小史莱姆
func spawn_small_slimes():

	var split_count = randi_range(split_count_min, split_count_max)
	
	for i in range(split_count):
		if slime_scene == null:
			return
			
		var tempSlime = slime_scene.instantiate()
		
		# 最小不能低于0次
		var tempSlitTimes = max(split_times - 1,0)
		
		# 设置子史莱姆的位置（在父史莱姆周围随机位置）
		var random_angle = randf() * 2 * PI
		var random_distance = randf() * spawn_radius
		var spawn_position = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
		tempSlime.global_position = spawn_position
		
		tempSlime.initData(0.5, tempSlitTimes)
		
		if get_tree().get_first_node_in_group("main") == null:
			print("找不到main场景，游戏可能结束了。by:level.gd")
			return
		get_tree().get_first_node_in_group("main").add_child.call_deferred(tempSlime)
	
		
