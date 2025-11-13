extends Node
var viewport
var enemyspath:Array=[
	'res://enemy/zomble.tscn',
	'res://enemy/flyDemon.tscn',
	'res://enemy/slime.tscn',
	
]
var enemys:Dictionary
var memEnemys:Array
var currentLevel:int =0
var enemysSpanwFinsh:Array =[]
var spawnQueue:Array
var enemysKeys:Array


func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_PAUSABLE
	loadAllenemy()
	viewport=get_viewport().get_visible_rect()
	Eventmanger.NextLevel.connect(enterLevel)
	Eventmanger.GameStart.connect(enterLevel)
	Eventmanger.restartGame.connect(_restart)
	
@warning_ignore('unused_parameter')
func _physics_process(delta: float) -> void:
	pass
	

func loadAllenemy():
	for i in enemyspath.size():
		var path:String = enemyspath[i]
		var sname = path.get_file().get_basename()
		enemys.set(sname,load(path))
		if i%3 :
			await get_tree().process_frame
	
	# 获取并随机打乱敌人顺序
	enemysKeys = enemys.keys()
	enemysKeys.shuffle()
	
func getrandipos():
	var randipos:Vector2
	if randi()%2:
		randipos.x = viewport.position.x
		randipos.y = randf_range(viewport.size.y*0.75,0)
	else:
		randipos.x = viewport.size.x
		randipos.y = randf_range(viewport.size.y*0.75,0)
		
	return randipos
	
func spawnenemy(_spawnQueue:Array,spawncd:float):
	enemysSpanwFinsh.append(false)
	var cd = spawncd
	if get_tree().get_first_node_in_group("main") == null:
		print("找不到main场景，游戏可能结束了。by:level.gd")
		return
	var obj =_spawnQueue.pop_front()
	var tempPack =obj[0]
	var tempMul = obj[1]
	var temptimer= get_tree().create_timer(cd,false)
	
	var temp = tempPack.instantiate()
	temp.initData(tempMul)
	temp.position = getrandipos()
	get_tree().get_first_node_in_group("main").add_child.call_deferred(temp)
	cd -= 0.05
	if cd <= 0.5 :
		cd =1
	if _spawnQueue.is_empty():
		enemysSpanwFinsh.clear()
		return
	temptimer.timeout.connect(func():
		spawnenemy(_spawnQueue,cd)
	)
	

func enterLevel():
	currentLevel +=1
	getSpawnQueue()
	spawnenemy(spawnQueue,1.0)
	
func _restart():
	currentLevel = 0
	if not memEnemys.is_empty():
		for i in memEnemys:
			if is_instance_valid(i):
				i.queue_free()
	
		

func getSpawnQueue():
	var baseEnemyCount:int = (currentLevel-1)*3+5
	var eliiteEnemyCount:int= int (baseEnemyCount/5.0)
	var baseEnemys:Array
	var enemysSpawnType:int= min((currentLevel-1)/5.0+1,enemys.size())
	for i in range(enemysSpawnType):
		baseEnemys.append(enemys.get(enemysKeys[i]))
		
	for i in range(baseEnemyCount):
		var temp = baseEnemys[((randi()%baseEnemys.size())-1)]
		var mul = 1
		var temparray =[
			temp,mul
		]
		spawnQueue.append(temparray)
		
	for i in range(eliiteEnemyCount):
		var temp = baseEnemys[((randi()%baseEnemys.size())-1)]
		var mul = randf_range(1.2,1.8)
		var temparray =[
			temp,mul
		]
		spawnQueue.append(temparray)
		
	if currentLevel%5 ==0:
		var boss
		var mul = 2.0
		if (currentLevel/5.0 ) <=enemys.size()-1:
			boss =enemys.get(enemysKeys[currentLevel/5.0])
		else:
			var temp = randi()%enemys.size()
			boss = enemys.get(temp)
		var temparray =[
			boss,mul
		]
		spawnQueue.append(temparray)
	print("当前关卡："+str(currentLevel)+",共生成"+str(baseEnemyCount)+"个普通敌人,"+str(eliiteEnemyCount)+"个精英敌人。不计算boss。")
	spawnQueue.shuffle()
	return spawnQueue
