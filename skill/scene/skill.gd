extends Control
@export var Data:skill
@onready var texture_rect: TextureRect = $card_bg/VBoxContainer/MarginContainer/TextureRect
@onready var rich_text_label: RichTextLabel = $card_bg/card/MarginContainer/RichTextLabel
@onready var label: Label = $card_bg/card/MarginContainer2/Label

var card_bk = preload('res://skill/asset/back.png')
var skill_name:String
var tips:String
var header:String
var skill_cname:String
###可延伸技能
var derivedSkill:Dictionary
var sprite
func GetData():
	if Data.sprite == null:
		texture_rect.texture = load('uid://brxi0odd5t6ap')
	else:
		texture_rect.texture =Data.sprite
	sprite =Data.sprite
	skill_name = Data.skill_name
	header = Data.skill_type
	skill_cname = Data.skill_cname
	tips = Data.tips
	derivedSkill = Data.derivedSkill
	pass
	
func _ready() -> void:
	SkllWarmUp()
	GetData()
	_bbcodeset()
	_SubSelfFromSkillBox()
	addDerivedSkillToSkillBox()
	
func _process(_delta: float) -> void:
	_skill()
	pass

func _skill():
	pass
	
func _skillSignal():
	
	return 0
	


func _bbcodeset():
	label.text = header
	var bbcodeText = """
	[b]{skill_cname}[/b]：{tips}
	""".format({
	"skill_cname": skill_cname, # 修正了拼写
	"tips": tips
	})
	rich_text_label.text = bbcodeText
	pass
	
func _skillEmit(_dic:Dictionary={}):
	var card_pile:TextureRect = get_tree().get_first_node_in_group(&'card_pile')
	var card_moveFollow:Path2D = get_tree().get_first_node_in_group(&'cardPath2D')
	if card_pile == null or card_moveFollow == null:
		push_error("无法获取card_pile。or 无法获取path。by：skill.gd")
	var temp_cardBk = TextureRect.new()
	temp_cardBk.texture = card_bk
	temp_cardBk.show()
	var pathfollow = PathFollow2D.new()
	card_moveFollow.add_child(pathfollow)
	pathfollow.rotates = false
	pathfollow.rotation = 0
	pathfollow.add_child(temp_cardBk)
	temp_cardBk.scale = Vector2(0.1,0.1)
	temp_cardBk.pivot_offset = temp_cardBk.size/2.0
	temp_cardBk.position = temp_cardBk.size/2.0*0.9*-1
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(pathfollow,^"progress_ratio",1.0,0.2)
	tween.parallel().tween_property(temp_cardBk,^"scale",Vector2(0.5,0.5),0.2)
	tween.tween_property(temp_cardBk,^"scale",Vector2(0,0.5),0.3)
	tween.tween_callback(func():
		self.pivot_offset = self.size/2
		self.scale=Vector2(0,0.5)
		self.global_position = temp_cardBk.global_position
		self.show()
	)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self,^"scale",Vector2(0.5,0.5),0.3)
	await  tween.finished
	await get_tree().create_timer(0.2).timeout
	var tween002 =get_tree().create_tween()
	tween002.parallel().tween_property(self,^"modulate",Color(1.0, 1.0, 1.0, 0.0),0.2)
	tween002.parallel().tween_property(self,^"scale",Vector2(0.6,0.6),0.2)
	await tween002.finished
	self.hide()
	self.modulate = Color(1.0, 1.0, 1.0)
	temp_cardBk.queue_free()
	pathfollow.queue_free()

	return 
	
func _SubSelfFromSkillBox():
	SkillManager._SubSkillBox(skill_name)

func SkllWarmUp():
	self.hide()
	var vie = get_viewport_rect()
	self.position = vie.size*2
	self.show()
	await get_tree().process_frame
	self.hide()
	
func addDerivedSkillToSkillBox():
	if derivedSkill.is_empty():
		return
	else:
		for i in derivedSkill.keys():
			var dic:Dictionary = derivedSkill.get(i)
			SkillManager._addSkill(i,load(dic.get("path")),dic.get("count"))
			
