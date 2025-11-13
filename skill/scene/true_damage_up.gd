extends "res://skill/scene/skill.gd"

func _skillEmit(_dic:Dictionary={}):
	await super()
	Eventmanger.playerTrueDamageUp.emit()
	queue_free()
	pass
