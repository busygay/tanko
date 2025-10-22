extends Control
@onready var header: HBoxContainer =$MarginContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/Panel/HBoxContainer/headerVbox/header
@onready var content: VBoxContainer = $MarginContainer/NinePatchRect/VBoxContainer/MarginContainer/VBoxContainer/Panel/HBoxContainer/ScrollContainer/content
@onready var accuracy_label: Label = $MarginContainer/NinePatchRect/VBoxContainer/AccuracyLabel
@onready var next: TextureButton =$MarginContainer/NinePatchRect/VBoxContainer/NEXT


var errorWord:Dictionary
var correctWord:Dictionary
var Accuracy:float
func _ready() -> void:
	Eventmanger.levelOver.connect(_ShowUI)
	
	 
	pass
	
func _resetData():
	errorWord.clear()
	correctWord.clear()
	errorWord=Jlptn5.errorWord.duplicate()
	correctWord=Jlptn5.correctWord.duplicate()
	Jlptn5._clearWord()
	calculate_accuracy()

	

func _on_correct_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		clearChild()
		showWord(true)
		pass
			
	pass # Replace with function body.


func _on_error_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		clearChild()
		showWord(false)
	
	pass # Replace with function body.

func showWord(isCorrect:bool):
	if isCorrect:
		for i in correctWord:
			var tempword = correctWord.get(i)
			var temp =header.duplicate()
			if temp.get_child_count() ==3:
				temp.get_child(0).text = tempword.get("假名")
				temp.get_child(1).text = tempword.get("日语汉字")
				temp.get_child(2).text = tempword.get("中文翻译")
				content.add_child(temp)
			else:
				push_error("header的节点数量不对。by:WordConfirm.gd")
	else:
		for i in errorWord:
			var tempword = errorWord.get(i)
			var temp =header.duplicate()
			if temp.get_child_count() ==3:
				temp.get_child(0).text = tempword.get("假名")
				temp.get_child(1).text = tempword.get("日语汉字")
				temp.get_child(2).text = tempword.get("中文翻译")
				content.add_child(temp)
			else:
				push_error("header的节点数量不对。by:WordConfirm.gd")
func clearChild():
	for i in content.get_children():
		i.queue_free()

func _ShowUI():
	_resetData()
	Eventmanger.UIHideAll.emit(self)
	showWord(true)
	
func _on_next_pressed() -> void:
	Eventmanger.ShowShoping.emit(true)
	get_tree().get_first_node_in_group("main").islevelDone=true
	clearChild()
	pass # Replace with function body.

func calculate_accuracy():
	var correct_count = correctWord.size()
	var error_count = errorWord.size()
	var total_count = correct_count + error_count
	
	
	if total_count == 0:
		# 避免除以零错误。如果没有单词，准确率可以认为是0。
		Accuracy = 0.0
	else:
		# 确保进行浮点除法
		Accuracy = float(correct_count) / total_count
	
	# 将准确率乘以100，并转换为整数（截断小数部分）用于显示百分比
	# 如果希望四舍五入，可以使用 round() 函数： int(round(Accuracy * 100))
	accuracy_label.text = "准确率：%d%%" % int(Accuracy * 100)
