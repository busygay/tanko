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
	Eventmanger.setequidDAta.connect(_setunequip)
	Eventmanger.equidSkill.connect(equipSkill)
	
func _setunequip(skillnode:):
	skillnode.get_parent().remove_child(skillnode)
	unequip.append(skillnode)
	pass
func _returnUnequid():
	return unequip

func equipSkill(tiggerd:StringName,skillnode):
	if tigger.has(tiggerd):
		#skillnode.get_parent().remove_child(skillnode)
		tigger.get(tiggerd).add_child(skillnode)
		
	pass
	
