extends HBoxContainer
@onready var texture_rect: TextureRect = $Control/iconBG/MarginContainer/Control/TextureRect
@onready var skill_name: Label = $NinePatchRect/MarginContainer/VBoxContainer/skillName
@onready var skill_tips: Label = $NinePatchRect/MarginContainer/VBoxContainer/skillTips
var data



func _ready() -> void:
	texture_rect.texture=data.sprite
	skill_name.text=data.skill_cname
	skill_tips.text=data.tips
func _setdata(_data):	
	data = _data
