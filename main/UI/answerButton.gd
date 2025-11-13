extends Control
@onready var button: TextureButton = $TextureButton
@onready var label: Label = $TextureButton/MarginContainer/Label


var isanswer:bool
var word
func _ready() -> void:
	self.size = button.size
	

func _setData(isans,sword):
	if sword =="":
		push_error("单词有问题")
	label.text=sword
	isanswer=isans
	if isanswer :
		self.add_to_group("isanswer")

func _setTiltleData(sword:Dictionary):
	word =sword
	pass



func _setcolor():
	self.modulate =  Color(0.0, 1.0, 0.231)


func _on_texture_button_pressed() -> void:
	if isanswer:
		self.modulate = Color(0.0, 1.0, 0.231)
		Eventmanger.answered.emit(true)
		Jlptn5._addCorrectWord(word)
		
		# 回答正确，减少错误次数
		var answering_node = get_tree().get_first_node_in_group("answering")
		if answering_node:
			var current_word = answering_node._getCurrentTitleWord()
			if current_word:
				Jlptn5._updateErrorWordCount(current_word, -1)
	else :
		self.modulate = Color(1.0, 0.0, 0.0)
		Eventmanger.answered.emit(false)
		Jlptn5._addErrorWord(word)
		
		# 回答错误，增加错误次数
		var answering_node = get_tree().get_first_node_in_group("answering")
		if answering_node:
			var current_word = answering_node._getCurrentTitleWord()
			if current_word:
				Jlptn5._updateErrorWordCount(current_word, 3)
	Eventmanger.answerFinsh.emit()
	pass # Replace with function body.
