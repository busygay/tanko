extends "res://skill/scene/skill.gd"

# 基础发射数量 (初始1 + 5次升级)
var baseCount: int = 6
# 基础跳弹次数 (初始1 + 5次升级)
var baseRicochet: int = 6

var lock: bool = true
var player: Node

func _ready() -> void:
	super ()
	Eventmanger.playerShooted.connect(ricoChet)
	# 获取玩家节点，这里假设组名为 'player'
	player = get_tree().get_first_node_in_group("player")

# 弹幕精通不通过常规升级提升，而是直接满级

func _skillEmit(_dic: Dictionary = {}):
	print("barrage_mastery _skillEmit: 触发")
	await super ()
	
	if _dic.has("fiveCombo"):
		# 5连击时：
		# 发射数量翻5倍 (6 * 5 = 30)
		# 跳弹次数增强 (基础5 + 5升级 = 10)
		print("barrage_mastery: 触发fiveCombo，发射%d发子弹，跳弹增强" % (baseCount * 5))
		Eventmanger.playerbulletCount.emit(baseCount * 5)
		baseRicochet = 10 # 5 (特殊基础) + 5 (虚拟升级值)
		lock = false
	else:
		# 普通触发
		print("barrage_mastery: 发射%d发子弹" % baseCount)
		Eventmanger.playerbulletCount.emit(baseCount)
		baseRicochet = 6 # 1 (基础) + 5 (虚拟升级值)
		lock = false

func ricoChet(enemy, pos: Vector2, baseDamage: float):
	if lock:
		return
	else:
		lock = true
		var line
		var start
		var selectTarget: Array
		var count
		var allenemys: Array
		
		# 确保 player 引用有效
		if not is_instance_valid(player):
			player = get_tree().get_first_node_in_group("player")
			if not is_instance_valid(player):
				return
				
		allenemys = player.enemy.duplicate()
		
		if is_instance_valid(enemy):
			start = enemy.position
			selectTarget.append(enemy)
			if allenemys.has(enemy):
				allenemys.erase(enemy)
			
			# 使用当前设定的 baseRicochet
			count = min(allenemys.size(), baseRicochet)
		else:
			start = pos
			count = min(allenemys.size(), baseRicochet)
			
		for i in range(count):
			line = Line2D.new()
			line.width = 2 # 稍微加粗一点示威
			line.default_color = Color(1, 0.8, 0, 1) # 金色弹道
			
			var y: int = 0
			# 寻找下一个有效目标
			while selectTarget.has(allenemys[y]) or (not is_instance_valid(allenemys[y])):
				y += 1
				if y > allenemys.size() - 1:
					line.queue_free() # 没找到目标，清理当前的 line
					return
			
			selectTarget.append(allenemys[y])
			var ends = allenemys[y].position
			line.points = [start, ends]
			start = ends
			get_tree().root.add_child(line)
			
			var time = get_tree().create_timer(0.1)
			time.timeout.connect(func():
				line.queue_free()
			)
			
			var next_enemy = allenemys[y]
			if next_enemy.has_method("gotHurt"):
				next_enemy.gotHurt(baseDamage)
