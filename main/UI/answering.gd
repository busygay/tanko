extends Control
const ANSWER_BUTTON = preload('res://main/UI/answer_button.tscn')

@onready var title_label: Label = $VBoxContainer/NinePatchRect/VBoxContainer/titleLabel
@onready var h_box_container_1: HBoxContainer =$VBoxContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer1
@onready var h_box_container_2: HBoxContainer =$VBoxContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2
@onready var nine_patch_rect: NinePatchRect = $VBoxContainer/NinePatchRect
@onready var skip_button: Button = $VBoxContainer/NinePatchRect/VBoxContainer/SkipButton


var allkeys:Array
var tiltle_ran:int
var tiltle:Dictionary
var error_word
var current_title_word:Dictionary  # 存储当前题目的单词数据
var question_count:int = 0  # 题目计数器，用于触发特殊题型
var current_question_type:String = "normal"  # 当前题目类型：normal, error_review, word_reorder
var word_reorder_data:Dictionary  # 单词重组模式的数据
var selected_characters:Array = []  # 单词重组模式中已选择的字符
func _ready() -> void:
	Jlptn5._gameStart()
	_initset()
	Eventmanger.answered.connect(_reloadtiltle)
	Eventmanger.setbulletPos(self,true)
	Eventmanger.setpowerPos(self,true)
	skip_button.pressed.connect(_on_skip_pressed)
##获取随机题目，返回一个拥有题目所有信息的字典，包含中文翻译，日语汉字，混淆词等

	
##获取错误答案，放回一个拥有2个错误答案的数组，答案由随机日语汉字和假名随机组成

func _initset():
	_settilte()

func _settilte():
	# 增加题目计数器
	question_count += 1
	
	# 检查是否触发特殊题型（每5道题后）
	if question_count > 1 and question_count % 5 == 0:
		_triggerSpecialQuestion()
		return
	
	# 普通题目
	_setNormalQuestion()

func _setNormalQuestion():
	current_question_type = "normal"
	title_label.text = ""
	for i in h_box_container_1.get_children():
		i.queue_free()
	for i in h_box_container_2.get_children():
		i.queue_free()
	var temp_Tiltle:Dictionary = Jlptn5._getNextWordData()
	var temp_key = temp_Tiltle.keys()[0]
	tiltle =temp_Tiltle.get(temp_key)
	current_title_word = tiltle  # 保存当前题目的单词数据
	error_word = Jlptn5._getErrorWordData()
	
	error_word.append(tiltle.get("容易混淆的单词"))
	title_label.text = "    选择\""+temp_key+"\"的日文翻译"
	var Correct : int = randi()%4
	var tempy :int =0
	for i in range(4):
		if i<2:
			if i != Correct:
				var temp = ANSWER_BUTTON.instantiate() as Control
				h_box_container_1.add_child(temp)
				temp._setData(false,error_word[tempy])
				tempy +=1
				temp._setTiltleData(tiltle)
			else :
				var temp = ANSWER_BUTTON.instantiate() as Control
				h_box_container_1.add_child(temp)
				if not tiltle.get("日语汉字").is_empty():
					if randi()%10 <8:
						temp._setData(true,tiltle.get("日语汉字"))
					else :
						temp._setData(true,tiltle.get("假名"))
				else:
					temp._setData(true,tiltle.get("假名"))
				temp._setTiltleData(tiltle)
		else :
			if i != Correct:
				var temp = ANSWER_BUTTON.instantiate() as Control
				h_box_container_2.add_child(temp)
				temp._setData(false,error_word[tempy])
				tempy +=1
				temp._setTiltleData(tiltle)
			else :
				var temp = ANSWER_BUTTON.instantiate() as Control
				h_box_container_2.add_child(temp)
				if not tiltle.get("日语汉字").is_empty():
					if randi()%10 <8:
						temp._setData(true,tiltle.get("日语汉字"))
					else :
						temp._setData(true,tiltle.get("假名"))
				else:
					temp._setData(true,tiltle.get("假名"))
				temp._setTiltleData(tiltle)

func _triggerSpecialQuestion():
	var random_number = randi() % 10  # 0-9的随机数
	
	if random_number <= 4:
		# 触发错题消化插入模式
		_setErrorReviewQuestion()
	else:
		# 触发单词重组模式
		_setWordReorderQuestion()

func _setErrorReviewQuestion():
	current_question_type = "error_review"
	var error_review_word = Jlptn5._getHighestErrorWord()
	
	if error_review_word == null:
		# 如果没有错题，返回普通题目
		_setNormalQuestion()
		return
	
	# 使用错题作为普通选择题
	title_label.text = ""
	for i in h_box_container_1.get_children():
		i.queue_free()
	for i in h_box_container_2.get_children():
		i.queue_free()
	
	var temp_key = error_review_word.get("中文翻译", "")
	tiltle = error_review_word
	current_title_word = tiltle
	
	# 获取错误答案
	var error_options = Jlptn5._getErrorWordData()
	error_options.append(error_review_word.get("容易混淆的单词", ""))
	
	title_label.text = "    错题复习：选择\""+temp_key+"\"的日文翻译"
	var Correct : int = randi()%4
	var tempy :int =0
	for i in range(4):
		if i<2:
			if i != Correct:
				var temp = ANSWER_BUTTON.instantiate() as Control
				h_box_container_1.add_child(temp)
				temp._setData(false,error_options[tempy])
				tempy +=1
				temp._setTiltleData(tiltle)
			else :
				var temp = ANSWER_BUTTON.instantiate() as Control
				h_box_container_1.add_child(temp)
				if not tiltle.get("日语汉字").is_empty():
					if randi()%10 <8:
						temp._setData(true,tiltle.get("日语汉字"))
					else :
						temp._setData(true,tiltle.get("假名"))
				else:
					temp._setData(true,tiltle.get("假名"))
				temp._setTiltleData(tiltle)
		else :
			if i != Correct:
				var temp = ANSWER_BUTTON.instantiate() as Control
				h_box_container_2.add_child(temp)
				temp._setData(false,error_options[tempy])
				tempy +=1
				temp._setTiltleData(tiltle)
			else :
				var temp = ANSWER_BUTTON.instantiate() as Control
				h_box_container_2.add_child(temp)
				if not tiltle.get("日语汉字").is_empty():
					if randi()%10 <8:
						temp._setData(true,tiltle.get("日语汉字"))
					else :
						temp._setData(true,tiltle.get("假名"))
				else:
					temp._setData(true,tiltle.get("假名"))
				temp._setTiltleData(tiltle)

func _setWordReorderQuestion():
	print("DEBUG: 开始设置单词重组题目")
	current_question_type = "word_reorder"
	
	# 清空现有UI
	title_label.text = ""
	for i in h_box_container_1.get_children():
		i.queue_free()
	for i in h_box_container_2.get_children():
		i.queue_free()
	
	# 获取一个已掌握的单词作为重组题目
	var mastered_word = Jlptn5._getMasteredWordForReorder()
	print("DEBUG: 获取到的已掌握单词 = ", mastered_word)
	
	if mastered_word == null:
		# 如果没有已掌握的单词，返回普通题目
		print("没有已掌握的单词，返回普通题目")
		_setNormalQuestion()
		return
	
	# 从已掌握的单词创建题目格式
	var temp_Tiltle:Dictionary = {}
	var temp_key = mastered_word.get("中文翻译", "")
	temp_Tiltle[temp_key] = mastered_word
	tiltle = mastered_word
	current_title_word = tiltle
	
	# 获取单词重组数据
	word_reorder_data = Jlptn5._getWordReorderData(tiltle)
	print("DEBUG: 获取到的单词重组数据 = ", word_reorder_data)
	selected_characters.clear()
	print("DEBUG: 已清空 selected_characters 数组")
	
	title_label.text = "    单词重组：请组合出\""+temp_key+"\"的正确写法"
	
	# 创建字符按钮
	var button_index = 0
	for character in word_reorder_data.all_options:
		var char_button = Button.new()
		char_button.text = character
		char_button.custom_minimum_size = Vector2(60, 60)
		char_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		print("DEBUG: 创建字符按钮，字符 = ", character)
		# 连接点击信号
		char_button.pressed.connect(_on_character_button_pressed.bind(character, char_button))
		
		# 添加到容器
		if button_index < 4:
			h_box_container_1.add_child(char_button)
		else:
			h_box_container_2.add_child(char_button)
		
		button_index += 1
	
	print("DEBUG: 单词重组题目设置完成，共创建 ", button_index, " 个按钮")

func _on_character_button_pressed(character: String, button: Button):
	print("DEBUG: _on_character_button_pressed 被调用，character = ", character)
	print("DEBUG: current_question_type = ", current_question_type)
	
	if current_question_type != "word_reorder":
		print("DEBUG: 非单词重组模式，返回")
		return
	
	# 检查 word_reorder_data 是否正确初始化
	print("DEBUG: word_reorder_data = ", word_reorder_data)
	if word_reorder_data == null or not word_reorder_data.has("characters"):
		print("DEBUG: word_reorder_data 未正确初始化或缺少 characters 字段")
		return
	
	# 检查字符是否正确
	var target_characters = word_reorder_data.characters
	print("DEBUG: target_characters = ", target_characters)
	print("DEBUG: selected_characters.size() = ", selected_characters.size())
	
	# 检查数组越界
	if selected_characters.size() >= target_characters.size():
		print("DEBUG: 数组越界！selected_characters.size() >= target_characters.size()")
		return
		
	var expected_char = target_characters[selected_characters.size()]
	print("DEBUG: expected_char = ", expected_char)
	print("DEBUG: character = ", character)
	
	if character == expected_char:
		# 正确选择
		print("DEBUG: 字符匹配正确")
		selected_characters.append(character)
		button.disabled = true
		button.modulate = Color.GREEN
		
		# 给予即时奖励
		Eventmanger.answered.emit(true)
		
		# 检查是否完成
		if selected_characters.size() == target_characters.size():
			# 全部正确，额外奖励
			print("单词重组完成！额外奖励1AP")
			Eventmanger.wordReorderCompleted.emit()  # 发送单词重组完成信号
			
			# 延迟后加载下一题
			get_tree().create_timer(1.0).timeout.connect(func():
				_settilte()
			)
		else:
			# 显示当前进度
			var current_progress = ""
			for char_item in selected_characters:  # 修复变量名不一致问题
				current_progress += char_item
			print("当前进度: ", current_progress)
	else:
		# 错误选择，立即结束当前题目
		print("单词重组失败！字符不匹配")
		Eventmanger.answered.emit(false)
		
		# 延迟后加载下一题
		get_tree().create_timer(1.0).timeout.connect(func():
			_settilte()
		)

func _reloadtiltle(isanswer:bool):
	if isanswer:
		get_tree().create_timer(0.3).timeout.connect(func():
			_settilte()
			)
	else:
		get_tree().get_first_node_in_group(&"isanswer").call("_setcolor")
		get_tree().create_timer(0.5).timeout.connect(func():
			_settilte()
			)
	pass

func _getCurrentTitleWord():
	return current_title_word

func answerPanlePos():
	var temprect = nine_patch_rect.get_global_rect()
	print(temprect.position,temprect.size," 。by:answering.gd")
	return temprect

func _on_skip_pressed() -> void:
	# 跳过题目：不获得/损失资源，不触发技能，不影响错题记录和连击
	print("跳过按钮被点击")
	Eventmanger.questionSkipped.emit()  # 发送跳过信号
	Eventmanger.answerFinsh.emit()  # 触发答题结束事件
	# 直接加载下一题
	_settilte()
