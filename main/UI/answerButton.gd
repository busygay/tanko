extends Control
@onready var button: TextureButton = $TextureButton
@onready var label: Label = $TextureButton/MarginContainer/Label

var answerpanel
var wordStr:String


func _ready() -> void:
	label.text = wordStr
	

func setData(WordStr:String,ansPanel:Node):
	wordStr = WordStr
	answerpanel = ansPanel



func _setcolor():
	self.modulate =  Color(0.0, 1.0, 0.231)


func _on_texture_button_pressed() -> void:
	var iscorrect = answerpanel.checkAnswer(wordStr)
	if iscorrect:
		self.modulate = Color(0.0, 1.0, 0.231)
		#
	else :
		self.modulate = Color(1.0, 0.0, 0.0)
		

	pass # Replace with function body.
