extends "res://skill/scene/skill.gd"

const ROBOT_SCENE = preload("res://globalSkillData/robot.tscn")

var currentRobot: Node2D = null
var lightningBuffManger:Array = []


func _ready() -> void:
	super ()
	# Connection to any upgrade signals can be added here if needed in future

func _skillEmit(_dic: Dictionary = {}):
	await super ()
	spawnRobot(_dic)

func spawnRobot(_dic: Dictionary = {}):
	# 如果已经有一个机器人存在，先移除它
	if currentRobot != null:
		currentRobot.queue_free()
	
	# 实例化机器人场景
	var robotInstance = ROBOT_SCENE.instantiate()
	
	# 将机器人添加到主场景中
	var mainScene = get_tree().get_first_node_in_group(&"main")
	if mainScene:
		mainScene.add_child(robotInstance)
		
		# 获取玩家位置作为机器人的生成圆心
		var player = get_tree().get_first_node_in_group(&"player")
		if player:
			# 以玩家为圆心，在半径100的圆内随机生成机器人位置
			var randomAngle = randf() * 2 * PI  # 0到2π的随机角度
			var randomRadius = randf() * 100    # 0到100的随机半径
			var offsetX = cos(randomAngle) * randomRadius
			var offsetY = sin(randomAngle) * randomRadius
			robotInstance.global_position = player.global_position + Vector2(offsetX, offsetY)
		else:
			# 如果找不到玩家，使用默认位置
			robotInstance.global_position = Vector2(527, 901)  # 从main.tscn中看到的玩家默认位置
	else:
		push_error("无法找到主场景，机器人无法生成")
		return
	
	# 保存对当前机器人的引用
	currentRobot = robotInstance
	
	# 初始化机器人数据，传递字典
	if robotInstance.has_method("initData"):
		robotInstance.initData(_dic, self)
	else:
		push_error("机器人实例缺少initData方法")
	

func AddToLightningBuffManger(enemy1:Node2D):
	if is_instance_valid(enemy1):
		lightningBuffManger.append(enemy1)

func removeFromLightningBuffManger(enemy1:Node2D):
	if enemy1 in lightningBuffManger:
		lightningBuffManger.erase(enemy1)