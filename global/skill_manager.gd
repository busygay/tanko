extends Node

var _skillDataPath: Dictionary = {
	"doubleShoot": 'res://skill/resource/doubleShoot.tres',
	"cdSub": 'res://skill/resource/cdSub.tres',
	"baseDamageUp": 'res://skill/resource/baseDamageUp.tres',
	"ricochetShoot": "res://skill/resource/ricochetShoot.tres",
	"BT-7270": 'res://skill/resource/BT-7270.tres',
	"fullPower": 'res://skill/resource/fullPower.tres',
	"trueDamageUp": 'res://skill/resource/trueDamageUp.tres',
	"BT-7271": 'res://skill/resource/BT-7271.tres',
	"molotov": 'res://skill/resource/Molotov.tres',
	"landmine": 'res://skill/resource/Landmine.tres',
	
}
var _skillDataManager: Dictionary = {
}
var _skillDataCopy: Dictionary

var _SkillCount: Dictionary = {
	"doubleShoot": 1,
	"cdSub": 9,
	"baseDamageUp": 5,
	"ricochetShoot": 1,
	"BT-7270": 1,
	"fullPower": 1,
	"trueDamageUp": 5,
	"BT-7271": 1,
	"molotov": 1,
	"landmine": 1,
}
var _SkillCountCopy: Dictionary
func _ready() -> void:
	loadAllSkill()
	pass
	
func loadAllSkill():
	var count: int = 0
	for i in _skillDataPath:
		var temp = _skillDataPath.get(i)
		var obj = load(temp)
		_skillDataManager.set(i, obj)
		count += 1
		if count % 3 <= 0:
			await get_tree().process_frame
	_skillBoxSet()

	
func _skillBoxSet():
	_skillDataCopy = _skillDataManager.duplicate()
	_SkillCountCopy = _SkillCount.duplicate()
	pass

func _getRandomSkill():
	var RandomSkill: Array = []
	if _skillDataCopy.size() > 3:
		var tempkeys = _skillDataCopy.keys()
		for i in range(3):
			var temp = randi()%tempkeys.size()
			RandomSkill.append(_skillDataCopy.get(tempkeys.get(temp)))
			tempkeys.remove_at(temp)
			pass
	else:
		for i in _skillDataCopy:
			RandomSkill.append(_skillDataCopy.get(i))
	return RandomSkill
	

func _SubSkillBox(SkillName: String):
	if _skillDataCopy.has(SkillName) and _SkillCountCopy.has(SkillName):
		if _SkillCountCopy.get(SkillName) > 1:
			_SkillCountCopy.set(SkillName, _SkillCountCopy.get(SkillName) - 1)
		else:
			_skillDataCopy.erase(SkillName)
	
func _resetSkillBox():
	_SkillCountCopy = _SkillCount.duplicate()
	_skillDataCopy = _skillDataManager.duplicate()

func _addSkill(skillName: String, skillResource: Resource, SkillCount: int):
	if _skillDataCopy.has(skillName):
		return
	_skillDataCopy.set(skillName, skillResource)
	_SkillCountCopy.set(skillName, SkillCount)
	
func addSkillCount(SkillName: String, addCount: int):
	var tempCount = _SkillCountCopy.get(SkillName, null)
	if tempCount != null:
		_SkillCountCopy.set(SkillName, tempCount + addCount)
	else:
		_SkillCountCopy.set(SkillName, addCount)
		_skillDataCopy.set(SkillName, SkillName)
