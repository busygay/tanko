extends Control
const ANSWER_BUTTON = preload('res://main/UI/answer_button.tscn')

@onready var tiltle_label: Label = $VBoxContainer/NinePatchRect/VBoxContainer/titleLabel
@onready var h_box_container_1: HBoxContainer =$VBoxContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer1
@onready var h_box_container_2: HBoxContainer =$VBoxContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2
@onready var nine_patch_rect: NinePatchRect = $VBoxContainer/NinePatchRect
@onready var skip_button: Button = $VBoxContainer/NinePatchRect/VBoxContainer/SkipButton
@onready var timer: Timer = $Timer

var questionData
#	数据结构展示
#	questionData = {
#		"type":int,
#		"tiltle":dic,
#		"correctData":array,
#		"selectErrorWordData":array,
#		"errorButtonCount":int,
#	}


var question_count:int = 0  # 题目计数器，用于触发特殊题型

func _ready() -> void:
	Jlptn5._gameStart()
	_initset()
	Eventmanger.setbulletPos(self,true)
	Eventmanger.setpowerPos(self,true)
	skip_button.pressed.connect(_on_skip_pressed)
##获取随机题目，返回一个拥有题目所有信息的字典，包含中文翻译，日语汉字，混淆词等
##获取错误答案，放回一个拥有2个错误答案的数组，答案由随机日语汉字和假名随机组成

func _initset():
	_setTilte()

func _setTilte():
	# 增加题目计数器
	question_count += 1
	# 检查是否触发特殊题型（每5道题后）
	if question_count > 1 and question_count % 5 == 0:
		if randi()%2:
			questionData = Jlptn5.getNextQuestion(1).duplicate()
		else:
			questionData = Jlptn5.getNextQuestion(2).duplicate()
	
	else:	
		questionData = Jlptn5.getNextQuestion(0).duplicate()
	
	#	设置题目信息
	var tilteStrList=[
		["-选择题-请选择——","——的正确日语单词"],
		["-错题重做-请选择——","——的正确日语单词"],
		["-单词重组-请按顺序选择——","——日语汉字或假名"]
	]
	var str1  =  tilteStrList.get(questionData.type).get(0)
	var str2 = questionData.get("tiltle").get("中文翻译")
	var str3  = tilteStrList.get(questionData.type).get(1)
	tiltle_label.text =str1+str2+str3
	
	#	设置回答按钮，将正确答案和错误答案放入按钮组打乱后生成按钮
	
	var buttonArray:Array
	#	设置正确按钮，需要保存正确顺序。
	for i in questionData.get("correctData"):
		var tempButton = ANSWER_BUTTON.instantiate()
		tempButton.setData(i,self)
		buttonArray.append(tempButton)
	#	设置错误按钮，错误按钮需要先洗牌
	var errorWordStrArray = questionData.get("selectErrorWordData")
	errorWordStrArray.shuffle()
	for i in range(questionData.get("errorButtonCount")):
		var tempStr = errorWordStrArray.get(i)
		var tempButton = ANSWER_BUTTON.instantiate()
		tempButton.setData(tempStr,self)
		buttonArray.append(tempButton)
	
	#	清理残留按钮
	for i in h_box_container_1.get_children():
		i.queue_free()
	for i in h_box_container_2.get_children():
		i.queue_free()
	#	打乱顺序后生成按钮
	buttonArray.shuffle()
	var line1 = int(buttonArray.size()/2.0)
	var line2 = buttonArray.size()-line1
	for i in range(line1):
		var tempButton = buttonArray.pop_front()
		h_box_container_1.add_child(tempButton)
	for i in range(line2):
		var tempButton = buttonArray.pop_front()
		h_box_container_2.add_child(tempButton)
	#	buttonArray内的按钮添加进answering面板。
	
		
	
func checkAnswer(answer:String):
	var iscorrect:bool 
	var tempcorrectData:Array = questionData.get("correctData")
	if tempcorrectData.get(0) == answer:
		iscorrect = true
		tempcorrectData.erase(answer)
		if questionData.get("correctData").size() <=0:
			timer.start(0.5)
			
			if questionData.get("type") == 2:
				#新增信号，直接获取一点行动点。
				pass
	else:
		iscorrect = false
		timer.start(1)
		pass
	##	发送回答信号，包含是否回答正确，
	var count_change:int 
	if iscorrect :
		count_change =-1
	else :
		count_change = 3
	Jlptn5.updateWordCount(questionData.get("tiltle"),count_change)
	Eventmanger.answered.emit(iscorrect)
	return iscorrect


	


func answerPanlePos():
	var temprect = nine_patch_rect.get_global_rect()
	print(temprect.position,temprect.size," 。by:answering.gd")
	return temprect

func _on_skip_pressed() -> void:
	# 跳过题目：不获得/损失资源，不触发技能，不影响错题记录和连击
	print("跳过按钮被点击")
	Eventmanger.questionSkipped.emit()  # 发送跳过信号
	# 直接加载下一题
	_setTilte()


func _on_timer_timeout() -> void:
	_setTilte()
	pass # Replace with function body.
