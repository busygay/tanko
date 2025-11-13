extends Control
const ANSWER_BUTTON = preload('res://main/UI/answer_button.tscn')

@onready var title_label: Label = $VBoxContainer/NinePatchRect/VBoxContainer/titleLabel
@onready var h_box_container_1: HBoxContainer =$VBoxContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer1
@onready var h_box_container_2: HBoxContainer =$VBoxContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2
@onready var nine_patch_rect: NinePatchRect = $VBoxContainer/NinePatchRect


var allkeys:Array
var tiltle_ran:int
var tiltle:Dictionary
var error_word
var current_title_word:Dictionary  # 存储当前题目的单词数据
func _ready() -> void:
	Jlptn5._gameStart()
	_initset()
	Eventmanger.answered.connect(_reloadtiltle)
	Eventmanger.setbulletPos(self,true)
	Eventmanger.setpowerPos(self,true)
##获取随机题目，返回一个拥有题目所有信息的字典，包含中文翻译，日语汉字，混淆词等

	
##获取错误答案，放回一个拥有2个错误答案的数组，答案由随机日语汉字和假名随机组成

func _initset():
	_settilte()

func _settilte():
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
