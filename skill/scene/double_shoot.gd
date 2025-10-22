extends "res://skill/scene/skill.gd"

var baseCount:int = 1

func _ready() -> void:
	super()
	Eventmanger.doubleShootUP.connect(doubleShootUpFunc)
func _skill():
	super()
	pass
	
func _skillSignal():
	pass

	
func _skillEmit(_dic:Dictionary={}):
	await super()
	if _dic.has("fiveCombo"):
		Eventmanger.playerbulletCount.emit(baseCount*5)
	else:
		Eventmanger.playerbulletCount.emit(baseCount)

func doubleShootUpFunc():
	baseCount+=1
