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
	print("double_shoot _skillEmit: 触发，baseCount=%d" % baseCount)
	await super()
	if _dic.has("fiveCombo"):
		print("double_shoot _skillEmit: 触发fiveCombo，发射%d发子弹" % (baseCount*5))
		Eventmanger.playerbulletCount.emit(baseCount*5)
	else:
		print("double_shoot _skillEmit: 发射%d发子弹" % baseCount)
		Eventmanger.playerbulletCount.emit(baseCount)

func doubleShootUpFunc():
	baseCount+=1
