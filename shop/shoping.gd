extends Control
var tempSkillBox:Array
var skillrow:PackedScene =preload('res://shop/skillrow.tscn')
@onready var h_box_container: HBoxContainer = $Panel/HBoxContainer
var isLevelDone :bool

func _ready() -> void:
	Eventmanger.ShowShoping.connect(showShoping)
	Eventmanger.ShowSkillAssembly.connect(clearSkillRow)
	hide()
	pass
	


func showShoping(isOver:bool):
	Eventmanger.UIHideAll.emit(self)
	setSkillRow()
	isLevelDone = isOver
	pass


func setSkillRow():
	tempSkillBox.clear()
	tempSkillBox = SkillManager._getRandomSkill()
	if tempSkillBox.size()>3:
		push_error("tempSkillBox数量有问题！")
	for i in range(tempSkillBox.size()):
		var temp = skillrow.instantiate()
		h_box_container.get_child(i).add_child(temp)
		temp._setData(tempSkillBox.get(i))
	
func clearSkillRow():
	for i in range(3):
		if h_box_container.get_child(i).get_child_count() >0:
			if h_box_container.get_child(i).get_child(0) != null:
				h_box_container.get_child(i).get_child(0).queue_free()
