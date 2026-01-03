extends "res://skill/scene/skill.gd"

func _ready() -> void:
	super ()

func _skillEmit(_dic: Dictionary = {}):
	await super ()
	# TODO: 实现具体燃烧瓶逻辑
	if _dic.has("fiveCombo"):
		print("执行金黄色长效火墙逻辑")
	elif _dic.has("brokenCombo"):
		print("执行环形火焰保护圈逻辑")
	elif _dic.has("APSpent"):
		print("执行高能蓝火逻辑")
	else:
		print("执行常规随机火海逻辑")
