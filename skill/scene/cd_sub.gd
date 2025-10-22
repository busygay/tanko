extends "res://skill/scene/skill.gd"

func _ready() -> void:
	super()
	pass

func _skillEmit(_dic:Dictionary={}):
	await super()
	Eventmanger.playerCdSub.emit()
	queue_free()
	pass
