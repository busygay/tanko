extends "res://skill/scene/skill.gd"

func _skillEmit(_dic:Dictionary={}):
	await super()
	Eventmanger.ricochetShootUp.emit()
	queue_free()
