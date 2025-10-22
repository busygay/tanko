extends "res://skill/scene/skill.gd"

func _skillEmit(_dic:Dictionary={}):
	await super()
	Eventmanger.doubleShootUP.emit()
	queue_free()
