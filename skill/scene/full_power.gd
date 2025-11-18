extends "res://skill/scene/skill.gd"
@onready var break_buff: AnimatedSprite2D = $BreakBuff
@onready var buff: AnimatedSprite2D = $Buff


var bonus
var buffnode :AnimatedSprite2D = null
var liveTimer:Timer
func _ready():
	super()
	bonus = 100 # 伤害提升百分比，100表示提升100%
	buff.visible = false
	break_buff.visible = false
	liveTimer = Timer.new()
	liveTimer.wait_time = 10.0
	liveTimer.one_shot = true
	liveTimer.timeout.connect(func():
		if buffnode != null:
			buffnode.queue_free()
			buffnode = null
			Eventmanger.playerGlobalDamageBonusChange.emit(0)

	)
	add_child(liveTimer)
func _skillEmit(_dic:Dictionary={}):
	await super()
	creatBuff()
	
func getBuffPos():
	var getplayer = get_tree().get_first_node_in_group(&'player')
	var buffPos :Vector2 = getplayer.global_position + Vector2(-80, -70)
	return buffPos
	
func creatBuff():
	if buffnode == null:
		buffnode = buff.duplicate()
		buffnode.global_position = getBuffPos()
		get_tree().get_first_node_in_group(&'main').add_child(buffnode)
		buffnode.show()
		buffnode.play("buff")
		Eventmanger.playerGlobalDamageBonusChange.emit(bonus)
		liveTimer.start()
	else :
		var tempBreakBuff = break_buff.duplicate()
		tempBreakBuff.global_position = buffnode.get_child(0).global_position
		tempBreakBuff.show()
		get_tree().get_first_node_in_group(&'main').add_child(tempBreakBuff)
		tempBreakBuff.play("breakBuff")
		buffnode.offset = Vector2(0,8)
		buffnode.play("hit")
		Eventmanger.playerGlobalDmmageBonusChange.emit(0)
		buffnode.animation_finished.connect(func():
			buffnode.queue_free()
			buffnode = null
		,CONNECT_ONE_SHOT)
		tempBreakBuff.animation_finished.connect(func():
			tempBreakBuff.queue_free()
		,CONNECT_ONE_SHOT)
		liveTimer.stop()
		
		
