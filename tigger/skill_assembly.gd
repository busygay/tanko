extends Control
@onready var child: Control = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/child
@onready var marker_2d: Marker2D = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/child/Marker2D


@onready var tips_panel: Panel = $TipsPanel
@onready var tips_scroll_container: ScrollContainer = $TipsPanel/VBoxContainer/TipsScrollContainer

@onready var tips_label: Label = $TipsPanel/VBoxContainer/TipsLabel

const example:PackedScene = preload('uid://ic5kydsh7con')

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
	var unequidSkillBox:Array = tigger._returnUnequid()
	if unequidSkillBox.size()>0:
		var temp = unequidSkillBox.pop_back()
		temp.hide()
		self.add_child(temp)
		await get_tree().process_frame
		temp.pivot_offset = temp.size /2.0
		temp.scale = Vector2(0.8,0.8)
		temp.global_position = marker_2d.global_position
		temp.show()
		
		

func _on_button_left_pressed() -> void:
	pass # Replace with function body.


func _on_button_right_pressed() -> void:
	pass # Replace with function body.


func checkPoint(_node,pos):
	for i in allTigger:
		var temp:Rect2 = allTigger.get(i).get_global_rect()
		if temp.has_point(pos):
			var ob:PackedScene = load(_node.Data.get("path"))
			var obins = ob.instantiate()
			Eventmanger.equidSkill.emit(i,obins)
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
	for i in tips_scroll_container.get_children():
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
				tips_scroll_container.add_child(tempExample)
				await get_tree().process_frame
				
