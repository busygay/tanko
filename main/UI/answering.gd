extends Control
const ANSWER_BUTTON = preload('res://main/UI/answer_button.tscn')

@onready var tiltle_label: Label = $VBoxContainer/NinePatchRect/VBoxContainer/titleLabel
@onready var h_box_container_1: HBoxContainer = $VBoxContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer1
@onready var h_box_container_2: HBoxContainer = $VBoxContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2
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


var question_count: int = 0 # 题目计数器，用于触发特殊题型

func _ready() -> void:
	Jlptn5._gameStart()
	_initset()
	Eventmanger.setbulletPos(self, true)
	Eventmanger.setpowerPos(self, true)
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
		if randi() % 2:
			questionData = Jlptn5.getNextQuestion(1).duplicate()
		else:
			questionData = Jlptn5.getNextQuestion(2).duplicate()
	
	else:
		questionData = Jlptn5.getNextQuestion(0).duplicate()
	
	# 检查题目是否不足
	if questionData.get("isNotEnoughWord", false):
		_on_word_book_empty()
		return

	#	设置题目信息
	var tilteStrList = [
		["-选择题-请选择——", "——的正确日语单词"],
		["-错题重做-请选择——", "——的正确日语单词"],
		["-单词重组-请按顺序选择——", "——日语汉字或假名"]
	]
	var str1 = tilteStrList.get(questionData.type).get(0)
	var str2 = questionData.get("tiltle").get("中文翻译")
	var str3 = tilteStrList.get(questionData.type).get(1)
	tiltle_label.text = str1 + str2 + str3
	
	#	设置回答按钮，将正确答案和错误答案放入按钮组打乱后生成按钮
	
	var buttonArray: Array
	#	设置正确按钮，需要保存正确顺序。
	for i in questionData.get("correctData"):
		var tempButton = ANSWER_BUTTON.instantiate()
		tempButton.setData(i, self)
		buttonArray.append(tempButton)
	#	设置错误按钮，错误按钮需要先洗牌
	var errorWordStrArray = questionData.get("selectErrorWordData")
	errorWordStrArray.shuffle()
	for i in range(questionData.get("errorButtonCount")):
		var tempStr = errorWordStrArray.get(i)
		var tempButton = ANSWER_BUTTON.instantiate()
		tempButton.setData(tempStr, self)
		buttonArray.append(tempButton)
	
	#	清理残留按钮
	for i in h_box_container_1.get_children():
		i.queue_free()
	for i in h_box_container_2.get_children():
		i.queue_free()
	#	打乱顺序后生成按钮
	buttonArray.shuffle()
	var line1 = int(buttonArray.size() / 2.0)
	var line2 = buttonArray.size() - line1
	for i in range(line1):
		var tempButton = buttonArray.pop_front()
		h_box_container_1.add_child(tempButton)
	for i in range(line2):
		var tempButton = buttonArray.pop_front()
		h_box_container_2.add_child(tempButton)
	#	buttonArray内的按钮添加进answering面板。
	
		
func _disable_all_buttons():
	for btn in h_box_container_1.get_children():
		if btn.has_method("disable_button"):
			btn.disable_button()
	for btn in h_box_container_2.get_children():
		if btn.has_method("disable_button"):
			btn.disable_button()

func checkAnswer(answer: String):
	var iscorrect: bool
	var tempcorrectData: Array = questionData.get("correctData")
	if tempcorrectData.get(0) == answer:
		iscorrect = true
		tempcorrectData.erase(answer)
		if questionData.get("correctData").size() <= 0:
			timer.start(0.5)
			_disable_all_buttons()
			
			if questionData.get("type") == 2:
				#新增信号，直接获取一点行动点。
				pass
	else:
		iscorrect = false
		timer.start(1)
		_disable_all_buttons()
		pass
	##	发送回答信号，包含是否回答正确，
	var count_change: int
	if iscorrect:
		count_change = -1
	else:
		count_change = 3
	Jlptn5.updateWordCount(questionData.get("tiltle"), count_change)
	Eventmanger.answered.emit(iscorrect)
	return iscorrect


func answerPanlePos():
	var temprect = nine_patch_rect.get_global_rect()
	print(temprect.position, temprect.size, " 。by:answering.gd")
	return temprect

func _on_skip_pressed() -> void:
	# 跳过题目：不获得/损失资源，不触发技能，不影响错题记录和连击
	print("跳过按钮被点击")
	Eventmanger.questionSkipped.emit() # 发送跳过信号
	# 直接加载下一题
	_setTilte()


func _on_timer_timeout() -> void:
	_setTilte()
	pass # Replace with function body.


func _on_word_book_empty() -> void:
	# 暂停游戏
	get_tree().paused = true
	
	# 创建背景面板
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 设置半透明黑色背景
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)
	panel.add_theme_stylebox_override("panel", style_box)
	add_child(panel)
	
	# 创建垂直容器
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# 1. 提示标签
	var label = Label.new()
	label.text = "当前题库题目已用完！\n请选择需要启用的题库继续游戏"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(label)
	
	# 2. 题库选择 CheckButtons
	var check_buttons_container = VBoxContainer.new()
	vbox.add_child(check_buttons_container)
	
	var check_buttons = {}
	for book_name in Jlptn5.wordBookPath:
		var check_btn = CheckButton.new()
		check_btn.text = book_name
		# 默认选中当前正在使用的题库
		check_btn.button_pressed = book_name in Jlptn5.wordBookList
		check_buttons_container.add_child(check_btn)
		check_buttons[book_name] = check_btn
	
	# 3. 恢复游戏按钮
	var resume_btn = Button.new()
	resume_btn.text = "应用并继续游戏"
	resume_btn.custom_minimum_size = Vector2(200, 60)
	resume_btn.pressed.connect(func():
		var new_list = []
		for book_name in check_buttons:
			if check_buttons[book_name].button_pressed:
				new_list.append(book_name)
		
		if new_list.is_empty():
			# 如果未选择任何题库，提示用户（这里简单打印，也可以做更细致的UI提示）
			print("请至少选择一个题库")
			return
			
		# 更新题库设置
		Jlptn5._setWordBookList(new_list)
		# 重新加载题库数据 (强制重置)
		Jlptn5._gameStart(true)
		
		# 恢复游戏
		panel.queue_free()
		get_tree().paused = false
		
		# 重新尝试出题
		_setTilte()
	)
	vbox.add_child(resume_btn)
	
	# 4. 结束游戏按钮
	var gameover_btn = Button.new()
	gameover_btn.text = "结束游戏"
	gameover_btn.custom_minimum_size = Vector2(200, 60)
	gameover_btn.pressed.connect(func():
		panel.queue_free()
		get_tree().paused = false
		Eventmanger.gameover.emit()
	)
	vbox.add_child(gameover_btn)
