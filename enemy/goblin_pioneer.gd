extends "res://enemy/base_enemy.gd"

# 哥布林工兵特有的变量
@onready var pioneer_effect: Node2D = $pioneer_effect if has_node("pioneer_effect") else null

func _ready() -> void:
	baseDir = true  # 设置初始朝向为右
	super()
	# 设置哥布林工兵的属性
	speed = 65  # 中等速度，比基础敌人快一些
	attCd = 3   # 攻击冷却时间，平衡的攻击频率
	damage = 2  # 中等攻击力

# 重写initData函数以调整哥布林工兵的基础属性
func initData(Mul:float):
	super(Mul)
	# 哥布林工兵的基础生命值调整
	var temp = Level.currentLevel
	health = int(temp/4.0)*2 + 8  # 稍微更高的基础生命值
	
	# 根据等级倍数调整属性
	if Mul > 1:
		var healthMul:float = Mul * 0.9  # 生命值倍率稍微降低，保持平衡
		var sizeMul:float = Mul * 0.8   # 体型倍率稍微降低
		var speedMul:float = 2.0 - Mul * 0.7  # 速度倍率调整，保持中等速度
		var damageMul:float = Mul * 0.9  # 伤害倍率稍微降低
		
		health = int(health * healthMul)
		self.scale = self.scale * sizeMul
		speed = int(speed * speedMul)
		damage = int(damage * damageMul)
	
	# 确保移动速度在合理范围内
	if speed < 30:
		speed = 30
	if speed > 120:
		speed = 120

# 可以重写att函数以实现工兵特有的攻击方式
func att():
	if playerbox.is_empty():
		return
	var i = 0
	var temp = playerbox[i] as Node2D
	var maxcount = playerbox.size() - 1
	while not temp.has_method("getHurt"):
		i += 1
		if i > maxcount:
			return
		temp = playerbox[i]
	
	# 工兵攻击 - 造成标准伤害
	temp.getHurt(damage)
	
	# 可以在这里添加工兵特有的攻击效果
	# 例如：短暂降低玩家移动速度或攻击速度
	print("哥布林工兵攻击造成 ", damage, " 点伤害")

# 重写_enter_state函数以处理工兵特有的状态逻辑
func _enter_state(new_state:state, _last_state:state = state.nothing):
	_last_state = currentState
	if new_state != currentState or (new_state == state.hurt and _last_state == state.hurt):
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
					, CONNECT_ONE_SHOT)
			state.hurt:
				animation_player.play("hurt")
				animation_player.animation_finished.connect(func(_animeName):
					if _last_state != state.nothing:
						_enter_state(_last_state)
					, CONNECT_ONE_SHOT)
			state.death:
				animation_player.play("death")
				animation_player.animation_finished.connect(func(_animeName):
					die()
					, CONNECT_ONE_SHOT)
