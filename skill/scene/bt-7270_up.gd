extends "res://skill/scene/skill.gd"

func _skillEmit(_dic: Dictionary = {}):
	await super ()
	Eventmanger.bt7270UP.emit()
	queue_free()
