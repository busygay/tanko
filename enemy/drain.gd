extends "res://enemy/base_enemy.gd"

# 可以添加drain特有的变量
@onready var drain_effect: Node2D = $drain_effect if has_node("drain_effect") else null

var debuffPackscene : PackedScene = load("res://main/debuff.tscn")
var debuff:Node
func _ready() -> void:
	baseDir = false  # 设置初始朝向
	super()
	attCd = 2  # 设置攻击冷却时间

# 重写_enter_state函数以处理drain特有的状态逻辑
func _enter_state(new_state:state,_last_state:state = state.nothing):
	_last_state = currentState
	if new_state != currentState or (new_state ==state.hurt and _last_state == state.hurt):
		currentState = new_state
		match currentState:
			state.idle:
				animation_player.play("idle")
			state.walk:
				animation_player.play("walk")
			state.att:
				animation_player.play("att")
				timer.start(attCd)
				# 在动画中途触发攻击伤害
				animation_player.animation_finished.connect(func(_animeName):
					_enter_state(state.idle)
					,CONNECT_ONE_SHOT)
			state.hurt:
				animation_player.play("hurt")
				animation_player.animation_finished.connect(func(_animeName):
					if _last_state != state.nothing:
						_enter_state(_last_state)
					,CONNECT_ONE_SHOT)
			state.death:
				animation_player.play("death")
				animation_player.animation_finished.connect(func(_animeName):
					die()
					,CONNECT_ONE_SHOT)

# 可以重写att函数以实现特殊的吸取攻击
func att():
	if playerbox.is_empty():
		return
	var i =0
	var temp  = playerbox[i] as Node2D
	var maxcount = playerbox.size()-1
	while not  temp.has_method("getHurt"):
		i +=1
		if i >maxcount:
			return
		temp = playerbox[i]
	temp.getHurt(damage)
	debuff = debuffPackscene.instantiate()
	temp.add_child(debuff)
	debuff.SetColor( Color(1,1,1,1))
	debuff.SetLiveTime(3)

	# 可以在这里添加吸取生命值的逻辑
	# 例如：health += damage * 0.5  # 吸取50%伤害值作为生命值
