extends Control
@onready var child: Control = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/child
@onready var marker_2d: Marker2D = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/child/Marker2D


@onready var tips_panel: Panel = $TipsPanel
@onready var tips_scroll_container: ScrollContainer = $TipsPanel/VBoxContainer/TipsScrollContainer

@onready var tips_label: Label = $TipsPanel/VBoxContainer/TipsLabel

const example:PackedScene = preload('uid://ic5kydsh7con')

var currentSkill:Node
@onready var allTigger:Dictionary = {
	"onCombo":$Panel/MarginContainer/VBoxContainer/HBoxContainer3/onCombo,
	"twoCombo":$Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxLeft/twoCombo,
	"fiveCombo":$Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxLeft/fiveCombo,
	"brokenCombo":$Panel/MarginContainer/VBoxContainer/HBoxContainer3/brokenCombo,
	"APGained":$Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxRight/APGained,
	"APSpent":$Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxRight/APSpent
}

var tiggerTips:Dictionary={
	"onCombo":"处于连答状态时，每10秒触发一次技能。",
	"twoCombo":"二连答时触发一次技能。",
	"fiveCombo":"五连答时触发一次技能，通常会加强技能的能力。",
	"brokenCombo":"连答中断时，触发一次技能。",
	"APGained":"获得一点行动点时，触发一次技能。",
	"APSpent":"消耗一点行动点时，触发一次技能。"
}
var tigger
func _ready() -> void:
	ConnectTigger()
	Eventmanger.drag_ended.connect(checkPoint)
	Eventmanger.ShowSkillAssembly.connect(ShowSkillAssembly)
	tigger =get_tree().get_first_node_in_group("tigger")
	self.hide()
	tips_panel.hide()
func ShowSkillAssembly():
	Eventmanger.UIHideAll.emit(self)
	_setSkill()
	
func _setSkill():
	# 如果当前正显示一个技能，先将其从场景中移除
	if is_instance_valid(currentSkill) and currentSkill.get_parent() == self:
		remove_child(currentSkill)
		tigger._setunequip(currentSkill)

	var unequidSkillBox:Array = tigger._returnUnequid()
	if unequidSkillBox.size()>0:
		currentSkill = unequidSkillBox.pop_back()
		
		currentSkill.hide()
		self.add_child(currentSkill)
		await get_tree().process_frame
		currentSkill.pivot_offset = currentSkill.size /2.0
		currentSkill.scale = Vector2(0.8,0.8)
		currentSkill.global_position = marker_2d.global_position
		currentSkill.show()
	else:
		currentSkill = null
		
		

func _on_button_left_pressed() -> void:
	if not is_instance_valid(currentSkill):
		return

	# 1. 将当前技能放回 tigger 的未装备池。根据 tigger.gd，它会被添加到末尾。
	remove_child(currentSkill)
	tigger._setunequip(currentSkill)
	
	# 2. 获取更新后的技能池
	var unequidSkillBox:Array = tigger._returnUnequid()
	
	# 3. 修正“获取上一个”的逻辑
	if unequidSkillBox.size() < 2:
		# 如果池中技能总数少于2个，切换无意义，只需取回唯一的那个技能。
		if not unequidSkillBox.is_empty():
			currentSkill = unequidSkillBox.pop_back()
		else:
			currentSkill = null
			return
	else:
		# a. 先弹出我们刚刚放回去的、位于数组末尾的技能。
		var just_returned_skill = unequidSkillBox.pop_back()
		# b. 再次弹出，这次得到的才是我们真正想要的“上一个”技能。
		currentSkill = unequidSkillBox.pop_back()
		# c. 为了维持循环，把最初的那个技能（just_returned_skill）放回到池子前面。
		unequidSkillBox.push_front(just_returned_skill)

	# 4. 显示新技能
	currentSkill.hide()
	self.add_child(currentSkill)
	await get_tree().process_frame
	currentSkill.pivot_offset = currentSkill.size /2.0
	currentSkill.scale = Vector2(0.8,0.8)
	currentSkill.global_position = marker_2d.global_position
	currentSkill.show()


func _on_button_right_pressed() -> void:
	# 此函数逻辑与 tigger.gd 中的 _setunequip 配合良好，无需修改。
	if not is_instance_valid(currentSkill):
		return

	# 1. 将当前技能放回 tigger 的未装备池
	remove_child(currentSkill)
	tigger._setunequip(currentSkill)
	
	# 2. 获取更新后的技能池
	var unequidSkillBox:Array = tigger._returnUnequid()
	if unequidSkillBox.is_empty():
		currentSkill = null
		return
		
	# 3. 从池子前面取出下一个技能
	currentSkill = unequidSkillBox.pop_front()
	
	# 4. 显示新技能
	currentSkill.hide()
	self.add_child(currentSkill)
	await get_tree().process_frame
	currentSkill.pivot_offset = currentSkill.size /2.0
	currentSkill.scale = Vector2(0.8,0.8)
	currentSkill.global_position = marker_2d.global_position
	currentSkill.show()


func checkPoint(_node,pos):
	for i in allTigger:
		var temp:Rect2 = allTigger.get(i).get_global_rect()
		if temp.has_point(pos):
			var ob:PackedScene = load(_node.Data.get("path"))
			var obins = ob.instantiate()
			Eventmanger.equidSkill.emit(i,obins)
			currentSkill=null
			_node.queue_free()
			if get_tree().get_first_node_in_group("main").islevelDone==false:
				get_tree().paused = false
				#var main = get_tree().get_first_node_in_group("main")
				Eventmanger.UIShowAll.emit()
				return
			if tigger._returnUnequid().size() <= 0:
				Eventmanger.NextLevel.emit()
				get_tree().paused = false
			break
	pass

func ConnectTigger():
	for i in allTigger:
		var temp = allTigger.get(i) as Panel
		temp.mouse_entered.connect(ShowTiggerTipsUi.bind(i))
		temp.mouse_exited.connect(HideTiggerTipsUi.bind())
		
func HideTiggerTipsUi():
	tips_panel.hide()
	for i in tips_scroll_container.get_child(0).get_children():
			i.queue_free()
	tips_label.text = ""


func ShowTiggerTipsUi(tiggerName:String):
	tips_panel.show()
	if get_global_mouse_position() < get_viewport_rect().size-tips_panel.size:
		tips_panel.position=Vector2(315,306)
	else:
		tips_panel.position=Vector2(10,306)
	tips_label.text=tiggerTips.get(tiggerName,"找不到提示")
	var temp:Node = get_tree().get_first_node_in_group("tigger").tigger.get(tiggerName)
	if temp !=null:
		if temp.get_child_count() >0:
			for i in temp.get_children():
				var tempExample = example.instantiate()
				tempExample._setdata(i)
				tempExample.show()
				tips_scroll_container.get_child(0).add_child(tempExample)
