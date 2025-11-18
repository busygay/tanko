extends Node

var unequip:Array=[]

@onready var tigger:Dictionary = {
	"onCombo":$onComboTigger,
	"twoCombo":$twoComboTigger,
	"fiveCombo":$fiveComboTigger,
	"brokenCombo":$brokenComboTigger,
	"APGained":$APGainedTigger,
	"APSpent":$APSpentTigger
}

func _ready() -> void:
	Eventmanger.setequipData.connect(_setunequip)
	Eventmanger.equipSkill.connect(equipSkill)
	
func _setunequip(skillnode:):
	skillnode.get_parent().remove_child(skillnode)
	unequip.append(skillnode)
	pass
func _returnUnequip():
	return unequip

func equipSkill(tiggerd:StringName,skillnode):
	if tigger.has(tiggerd):
		#skillnode.get_parent().remove_child(skillnode)
		tigger.get(tiggerd).add_child(skillnode)
		
	pass
	
