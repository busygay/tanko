extends Node

var unequip: Array = []

@onready var tigger: Dictionary = {
	"onCombo": $onComboTigger,
	"twoCombo": $twoComboTigger,
	"fiveCombo": $fiveComboTigger,
	"brokenCombo": $brokenComboTigger,
	"APGained": $APGainedTigger,
	"APSpent": $APSpentTigger
}

var fusion_skill_scene: PackedScene = preload("res://skill/scene/barrageMastery.tscn") # 新技能的预制体

func check_and_fuse_skills() -> bool:
	var double_shoot_node: Node = null
	var ricochet_shoot_node: Node = null
	
	# 辅助函数：在整个 tigger 系统中查找特定技能（包括已装备和未装备）
	var all_skills = []
	all_skills.append_array(unequip)
	for key in tigger:
		all_skills.append_array(tigger[key].get_children())
		
	for s_node in all_skills:
		if s_node.get_script().resource_path.ends_with("double_shoot.gd"):
			double_shoot_node = s_node
		elif s_node.get_script().resource_path.ends_with("ricochet_shoot.gd"):
			ricochet_shoot_node = s_node
			
	if double_shoot_node and ricochet_shoot_node:
		if double_shoot_node.get("upgrade_count") >= 5 and ricochet_shoot_node.get("upgrade_count") >= 5:
			# 移除旧技能
			if double_shoot_node in unequip:
				unequip.erase(double_shoot_node)
			double_shoot_node.queue_free()
			
			if ricochet_shoot_node in unequip:
				unequip.erase(ricochet_shoot_node)
			ricochet_shoot_node.queue_free()
			
			# 如果定义了融合技能，则创建新技能
			if fusion_skill_scene:
				var new_skill = fusion_skill_scene.instantiate()
				_setunequip(new_skill) # 添加到未装备列表
				SkillManager.addSkillCount("baseDamageUp", 5)
				print("技能融合成功！新技能已添加到未装备池。")

				return true
			else:
				print("技能融合成功！但 fusion_skill_scene 为空。")
				return true
	return false

func _ready() -> void:
	Eventmanger.setequipData.connect(_setunequip)
	Eventmanger.equipSkill.connect(equipSkill)
	
func _setunequip(skillnode: ):
	skillnode.get_parent().remove_child(skillnode)
	unequip.append(skillnode)
	pass
func _returnUnequip():
	return unequip

func equipSkill(tiggerd: StringName, skillnode):
	if tigger.has(tiggerd):
		#skillnode.get_parent().remove_child(skillnode)
		tigger.get(tiggerd).add_child(skillnode)
		
	pass
