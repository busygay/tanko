extends "res://skill/scene/skill.gd"

func _skillEmit(_dic: Dictionary = {}):
	await super ()
	Eventmanger.bt7271UP.emit()
	queue_free()
