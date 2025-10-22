extends "res://skill/scene/skill.gd"

func _ready() -> void:
	super()

func _skillEmit(_dic:Dictionary={}):
	await super()
	Eventmanger.playerBaseDamageUp.emit()
	queue_free()
	pass
