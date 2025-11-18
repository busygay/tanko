extends Node2D
@onready var control: Control = $CanvasLayer/answerpanel
@onready var powerBar: TextureProgressBar =$CanvasLayer/poewrBar
@onready var score_label: Label = $CanvasLayer/score/Panel/scoreLabel
@onready var player:players 
@onready var on_combo_timer: Timer = $onComboTimer
@onready var test:VBoxContainer = $CanvasLayer/test

const TURRET = preload('uid://d1t5wfugr4e7j')


var maxpower:int = 3
var power:int =1

var coin:int = 0
var word_Data:Dictionary
var allkeys:Array
var Correctcount :int =5
var combo:int =0
var wrongAnswerCount:int =0  # 新增：答错计数器


var NextLevelExpBase:int =5
var NextLevelExp:int= 5
var ExpPow:float = 2.1
var cosFre:float = 0.5
var playerLevel:int =1
var islevelDone:bool


var allInTreeEnemyCount:int = 0
var currentExp:
	set(new):
		currentExp=new
		if currentExp>=NextLevelExp:
			var temp = 1+cos(playerLevel*cosFre)*0.5
			NextLevelExp = int (pow(playerLevel,ExpPow))*NextLevelExpBase
			NextLevelExp =int ( temp*NextLevelExp)
			stopgamefunc()
			Eventmanger.ShowShoping.emit(false)
			islevelDone=false
			playerLevel +=1
			currentExp -=NextLevelExp
			

func _ready() -> void:



	
	currentExp = 0
	Eventmanger.GameStart.emit()
	Eventmanger.gameover.connect(stopgamefunc)
	player = get_tree().get_first_node_in_group(&'player')
	word_Data = Jlptn5.jlptN5_Data
	allkeys = word_Data.keys()
	Eventmanger.answered.connect(_addCorrectCount)
	Eventmanger.answered.connect(comboChange)
	Eventmanger.questionSkipped.connect(_on_question_skipped)  # 连接跳过信号
	Eventmanger.correctcountchange.connect(func():
		powerBar.value = Correctcount
		)
	Eventmanger.enemydeath.connect(upDatascore)
	Eventmanger.setpowerPos(powerBar,false)
	#Eventmanger.spawnEnemy.connect(spawn)
	Eventmanger.enterTreeEnemy.connect(enterTreeEnemyfunc)
	Eventmanger.exitTreeEnemy.connect(exitTreeEnemyfunc)

	# 连接单词重组完成的信号
	Eventmanger.wordReorderCompleted.connect(_on_word_reorder_completed)
		
func _addCorrectCount(iscorrect):
	if iscorrect:
		if Correctcount >=10 :
			if power <maxpower:
				Eventmanger.actionPointUp.emit()
				power+=1
				Correctcount = 5
			else:
				Correctcount = 10
		else:
			Correctcount +=1
		Eventmanger.correctcountchange.emit()
	else:
		wrongAnswerCount += 1
		if wrongAnswerCount >= 2:
			if Correctcount > 0:
				Correctcount -= 1
			wrongAnswerCount = 0
		Eventmanger.correctcountchange.emit()
func _on_word_reorder_completed():
	# 单词重组完成，额外奖励1AP
	print("单词重组完成，额外奖励1AP")
	if Correctcount >=10 :
		if power <maxpower:
			Eventmanger.actionPointUp.emit()
			power+=1
			Correctcount = 5
		else:
			Correctcount = 10
	else:
		Correctcount +=1
	Eventmanger.correctcountchange.emit()

func _on_question_skipped() -> void:
	# 跳过题目：不获得/损失资源，不触发技能，不影响错题记录
	# 连击数保持不变
	print("题目被跳过")

func upDatascore(_node):
	coin+=1
	score_label.text = ": %d"%coin

#func spawn(_node):
	#add_child.call_deferred(_node)

func comboChange(iscorrect):
	Eventmanger.comboChange.emit(iscorrect)
	if iscorrect:
		Eventmanger.parryInvincible.emit()
		currentExp+=1
		var tempCombo = combo
		combo += 1
		if tempCombo <2 and combo >=2:
			on_combo_timer.start()
		if combo >0 and combo%2==0:
			Eventmanger.twoComboEmit.emit()
		if combo>0 and combo%5==0:
			Eventmanger.fiveComboEmit.emit()
	else :
		if combo >=2:
			on_combo_timer.stop()
		if combo >0:
			Eventmanger.brokenComboEmit.emit()
		combo = 0


func stopgamefunc():
	get_tree().paused = true
	pass
func resumegamefunc():
	var temp = get_tree().paused
	if temp == true:
		get_tree().paused = false


func _on_on_combo_timer_timeout() -> void:
	Eventmanger.onComboEmit.emit()
	pass # Replace with function body.

func check_leaked_object(id):
	print("--- 正在检查实例 ID: ",id, " ---")
	
	# 使用 instance_from_id 查找对象
	var obj = instance_from_id(id)
	
	if is_instance_valid(obj):
		print("!!! 找到了对象 !!!")
		print("  - 对象类型 (Class): ", obj.get_class())
		print("  - 对象的脚本 (Script): ", obj.get_script())
		print("  - 对象的字符串表示: ", str(obj))
		# 我们可以尝试获取更多信息
		if obj is Resource:
			print("  - 这是一个资源, 路径: ", obj.resource_path)

		if obj is SceneTreeTimer:
			print("  - 这是一个 SceneTreeTimer!")
			print("    - 剩余时间: ", obj.time_left)

		if obj is Tween:
			print("  - 这是一个 Tween!")

	else:
		print("--- 对象未找到或已失效 ---")


func enterTreeEnemyfunc():
	allInTreeEnemyCount+=1
func exitTreeEnemyfunc():
	allInTreeEnemyCount-=1
	if allInTreeEnemyCount<=0 and Level.enemysSpanwFinsh.size()==0:
		stopgamefunc()
		Eventmanger.levelOver.emit()
